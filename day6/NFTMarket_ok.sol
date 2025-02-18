// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFT交易市场合约
 * @dev 实现NFT的上架、购买、取消上架等功能
 */
contract NFTMarket is IERC721Receiver, Ownable {
    // NFT上架信息结构
    struct Listing {
        address seller;    // 卖家地址
        uint256 price;    // 售价
        bool isActive;    // 是否在售
    }

    // 存储所有NFT的上架信息：NFT合约地址 => (tokenId => 上架信息)
    mapping(address => mapping(uint256 => Listing)) public listings;
    
    // 市场手续费率（以基点表示，100 = 1%）
    uint256 public feeRate = 250; // 2.5%
    
    // 平台累计收取的手续费
    uint256 public accumulatedFees;

    // 事件声明
    event NFTListed(address indexed nftContract, uint256 indexed tokenId, uint256 price, address indexed seller);
    event NFTSold(address indexed nftContract, uint256 indexed tokenId, address seller, address buyer, uint256 price);
    event ListingCanceled(address indexed nftContract, uint256 indexed tokenId, address indexed seller);
    event FeeRateUpdated(uint256 newFeeRate);
    event FeesWithdrawn(address to, uint256 amount);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev 上架NFT
     * @param _nftContract NFT合约地址
     * @param _tokenId NFT的tokenId
     * @param _price 售价
     */
    function listNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) external {
        require(_price > 0, "Price must be greater than 0");
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not the NFT owner");
        require(
            nft.getApproved(_tokenId) == address(this) ||
                nft.isApprovedForAll(msg.sender, address(this)),
            "NFT not approved for marketplace"
        );

        listings[_nftContract][_tokenId] = Listing({
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        emit NFTListed(_nftContract, _tokenId, _price, msg.sender);
    }

    /**
     * @dev 购买NFT
     * @param _nftContract NFT合约地址
     * @param _tokenId NFT的tokenId
     */
    function buyNFT(address _nftContract, uint256 _tokenId) external payable {
        Listing memory listing = listings[_nftContract][_tokenId];
        require(listing.isActive, "NFT not listed for sale");
        require(msg.value >= listing.price, "Insufficient payment");

        // 添加检查：确认 NFT 仍然在卖家手中
        require(
            IERC721(_nftContract).ownerOf(_tokenId) == listing.seller,
            "Seller no longer owns NFT"
        );

        // 计算手续费和卖家实际收入
        uint256 fee = (listing.price * feeRate) / 10000;
        uint256 sellerProceeds = listing.price - fee;

        accumulatedFees += fee;
        delete listings[_nftContract][_tokenId];

        // 转移 NFT 所有权 - 使用 transferFrom 而不是 safeTransferFrom
        IERC721(_nftContract).transferFrom(
            listing.seller,    // from: 卖家
            msg.sender,        // to: 实际买家
            _tokenId
        );

        // 如果买家是合约，确保其实现了接收接口
        if (msg.sender.code.length > 0) {
            require(
                IERC721Receiver(msg.sender).onERC721Received(
                    address(this),
                    listing.seller,
                    _tokenId,
                    ""
                ) == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }

        // 转账给卖家
        (bool success, ) = payable(listing.seller).call{value: sellerProceeds}("");
        require(success, "Failed to send ETH to seller");

        // 退还多余的ETH
        if (msg.value > listing.price) {
            (bool refundSuccess, ) = payable(msg.sender).call{
                value: msg.value - listing.price
            }("");
            require(refundSuccess, "Failed to refund excess");
        }

        emit NFTSold(
            _nftContract,
            _tokenId,
            listing.seller,
            msg.sender,
            listing.price
        );
    }

    /**
     * @dev 取消NFT上架
     * @param _nftContract NFT合约地址
     * @param _tokenId NFT的tokenId
     */
    function cancelListing(address _nftContract, uint256 _tokenId) external {
        Listing storage listing = _getListing(_nftContract, _tokenId);
        require(listing.isActive, "NFT not listed");
        require(listing.seller == msg.sender, "Not the seller");

        delete listings[_nftContract][_tokenId];

        emit ListingCanceled(_nftContract, _tokenId, msg.sender);
    }

    /**
     * @dev 更新市场手续费率（仅管理员）
     * @param _newFeeRate 新的手续费率（基点）
     */
    function updateFeeRate(uint256 _newFeeRate) external onlyOwner {
        require(_newFeeRate <= 1000, "Fee rate cannot exceed 10%");
        feeRate = _newFeeRate;
        emit FeeRateUpdated(_newFeeRate);
    }

    /**
     * @dev 提取平台累积的手续费（仅管理员）
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = accumulatedFees;
        require(amount > 0, "No fees to withdraw");
        
        accumulatedFees = 0;
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to withdraw fees");
        
        emit FeesWithdrawn(owner(), amount);
    }

    /**
     * @dev 查询NFT上架信息
     */
    function getListing(
        address _nftContract,
        uint256 _tokenId
    ) external view returns (Listing memory) {
        return _getListing(_nftContract, _tokenId);
    }

    /**
     * @dev 实现IERC721Receiver接口，允许合约接收NFT
     */
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // 允许合约接收ETH
    receive() external payable {}

    // 添加内部辅助函数来检查上架信息
    function _getListing(
        address _nftContract,
        uint256 _tokenId
    ) internal view returns (Listing storage) {
        return listings[_nftContract][_tokenId];
    }
}
