// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


// 合约已部署 sepolia测试网 地址:0x8B82B4056487A92C9c7FE6c0d433a2411103D945
contract Bank {
    // 定义管理员地址
    address public admin;

    // 记录每个地址的存款金额
    mapping(address => uint256) public deposits;

    // 用数组记录存款金额的前 3 名用户
    struct UserDeposit {
        address user;
        uint256 amount;
    }
    UserDeposit[3] public topDepositors;

    // 构造函数，初始化管理员地址为合约部署者
    constructor() {
        admin = msg.sender;
    }

    // 修饰器，仅允许管理员调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // 接收以太币的函数，允许直接向合约地址存款
    receive() external payable {
        updateDeposit(msg.sender, msg.value);
    }

    // 内部函数，更新存款信息和前 3 名用户
    function updateDeposit(address _user, uint256 _amount) internal {
        deposits[_user] += _amount;

        // 更新前 3 名用户
        for (uint256 i = 0; i < 3; i++) {
            if (deposits[_user] > topDepositors[i].amount) {
                // 将排名靠后的用户依次后移
                for (uint256 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j - 1];
                }
                topDepositors[i] = UserDeposit(_user, deposits[_user]);
                break;
            }
        }
    }

    // 管理员提取自定义金额资金到自己账户，输入单位为 ether
    function withdrawToSelf(uint256 _amountInEther) external onlyAdmin {
        uint256 amountInWei = _amountInEther * 1 ether;
        require(amountInWei <= address(this).balance, "Insufficient balance in the contract");
        payable(admin).transfer(amountInWei);
    }

    // 管理员向指定地址转账自定义金额，输入单位为 ether
    function withdrawToAddress(address payable _recipient, uint256 _amountInEther) external onlyAdmin {
        uint256 amountInWei = _amountInEther * 1 ether;
        require(amountInWei <= address(this).balance, "Insufficient balance in the contract");
        _recipient.transfer(amountInWei);
    }

    // 获取指定地址的存款金额
    function getDeposit(address _user) external view returns (uint256) {
        return deposits[_user];
    }

    // 获取前 3 名存款用户
    function getTopDepositors() external view returns (UserDeposit[3] memory) {
        return topDepositors;
    }
}