// SPDX-License-Identifier: MIT
// 合约已部署到sepolia测试网 合约地址: 0x66240242f031a17aDC960f581Cdd3563f5D8AaDc
// 查询存款前三名,采用地址数组,每次存款变动更新前三名.
pragma solidity ^0.8.20;

contract Bank {
    address public admin;
    // 记录每个地址的存款金额
    mapping(address => uint256) public deposits;
    // 只存储前三名地址
    address[3] public topDepositors;

    constructor() payable {
        admin = msg.sender;
        // 初始化 topDepositors
        for(uint i = 0; i < 3; i++) {
            topDepositors[i] = address(0);
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    receive() external payable {
        deposits[msg.sender] += msg.value;
        _updateTopDepositors(msg.sender);
    }

    function withdrawToSelf(uint256 _amountInWei) external onlyAdmin {
        require(_amountInWei <= deposits[admin], "Insufficient deposit");
        deposits[admin] -= _amountInWei;
        _updateTopDepositors(admin);
        payable(admin).transfer(_amountInWei);
    }

    function withdrawToAddress(address payable _recipient, uint256 _amountInWei) external onlyAdmin {
        require(_recipient != address(0), "Invalid address");
        require(_amountInWei <= deposits[_recipient], "Insufficient deposit");
        deposits[_recipient] -= _amountInWei;
        _updateTopDepositors(_recipient);
        _recipient.transfer(_amountInWei);
    }

    function _updateTopDepositors(address user) private {
        uint256 userAmount = deposits[user];
        
        // 先检查用户是否已在前三名中
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] == user) {
                // 如果余额为0，需要移除
                if (userAmount == 0) {
                    // 移动后续元素
                    for (uint256 j = i; j < 2; j++) {
                        topDepositors[j] = topDepositors[j + 1];
                    }
                    topDepositors[2] = address(0);
                }
                _sortTopDepositors();  // 无论是否为0都需要排序
                return;
            }
        }

        // 如果不在前三名中且余额不为0，检查是否应该进入
        if (userAmount > 0) {
            for (uint256 i = 0; i < 3; i++) {
                // 如果当前位置是空位或用户金额大于当前位置
                if (topDepositors[i] == address(0) || 
                    userAmount > deposits[topDepositors[i]]) {
                    // 移动数组元素
                    for (uint256 j = 2; j > i; j--) {
                        topDepositors[j] = topDepositors[j-1];
                    }
                    topDepositors[i] = user;
                    _sortTopDepositors();  // 添加新用户后需要排序
                    return;
                }
            }
        }
    }

    function _sortTopDepositors() private {
        // 先移除余额为0的地址
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] != address(0) && 
                deposits[topDepositors[i]] == 0) {
                for (uint256 j = i; j < 2; j++) {
                    topDepositors[j] = topDepositors[j + 1];
                }
                topDepositors[2] = address(0);
            }
        }

        // 按存款金额排序（从大到小）
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2 - i; j++) {
                if (topDepositors[j] == address(0) || 
                    (topDepositors[j + 1] != address(0) && 
                    deposits[topDepositors[j]] < deposits[topDepositors[j + 1]])) {
                    (topDepositors[j], topDepositors[j + 1]) = 
                        (topDepositors[j + 1], topDepositors[j]);
                }
            }
        }
    }

    function getTopDepositors() external view returns (
        address[3] memory addresses,
        uint256[3] memory amounts
    ) {
        addresses = topDepositors;
        for(uint i = 0; i < 3; i++) {
            amounts[i] = deposits[addresses[i]];
        }
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}