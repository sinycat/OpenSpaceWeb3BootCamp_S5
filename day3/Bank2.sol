// SPDX-License-Identifier: MIT
// 合约已部署到sepolia测试网 合约地址: 0x63183b56eDf292F91EdDbAb1d0997afbd90e80C3
// 查询存款前三名,采用结构体,每次存款变动更新前三名.

pragma solidity ^0.8.20;
/**
 * @title Bank
 * @dev 这是一个简单的银行合约，用于管理用户存款、允许管理员进行资金操作，并记录存款最多的前 3 名用户。
 */
contract Bank {
    // 定义管理员地址，管理员拥有特殊权限，如提取资金等操作
    address public admin;

    // 记录每个地址的存款金额
    // 键为用户地址，值为该用户在合约中的存款金额（以 wei 为单位）
    mapping(address => uint256) public deposits;

    // 存储前三名用户信息的数组
    UserDeposit[3] public topDepositors;

    // 用结构体数组记录存款金额的前 3 名用户
    // 每个结构体包含用户地址和对应的存款金额
    struct UserDeposit {
        address user; // 用户地址
        uint256 amount; // 用户的存款金额
    }

    /**
     * @dev 构造函数，在合约部署时执行
     * 初始化管理员地址为合约部署者，并设置为 payable 以允许部署时接收以太币
     */
    constructor() payable {
        // 将合约部署者的地址赋值给管理员地址
        admin = msg.sender;
        // 初始化 topDepositors 为空值
        for(uint i = 0; i < 3; i++) {
            topDepositors[i] = UserDeposit(address(0), 0);
        }
    }

    // 修饰器，仅允许管理员调用使用该修饰器的函数
    modifier onlyAdmin() {
        // 检查调用者的地址是否与管理员地址相同
        require(msg.sender == admin, "Only admin can call this function");
        // 如果条件满足，继续执行被修饰的函数
        _;
    }

    /**
     * @dev 接收以太币的函数，允许用户直接向合约地址存款
     * 当用户向合约地址发送以太币时，会自动调用该函数
     */
    receive() external payable {
        // 更新该用户的存款金额，将本次收到的以太币金额累加到其原有存款上
        deposits[msg.sender] += msg.value;
        // 更新前三名
        _updateTopDepositors(msg.sender, deposits[msg.sender]);
    }

    /**
     * @dev 获取合约账户以太坊的数量
     * @return 合约账户当前的以太币余额，单位为 wei
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev 管理员提取自定义金额资金到自己账户的函数，输入单位为 wei
     * 只有管理员可以调用该函数
     * @param _amountInWei 管理员要提取的以太币金额，单位为 wei
     */
    function withdrawToSelf(uint256 _amountInWei) external onlyAdmin {
        require(_amountInWei <= address(this).balance, "Insufficient balance in the contract");
        // 更新管理员存款
        deposits[admin] -= _amountInWei;
        // 更新前三名
        _updateTopDepositors(admin, deposits[admin]);
        // 转账
        payable(admin).transfer(_amountInWei);
    }

    /**
     * @dev 管理员向指定地址转账自定义金额的函数，输入单位为 wei
     * 只有管理员可以调用该函数
     * @param _recipient 接收转账的地址
     * @param _amountInWei 要转账的以太币金额，单位为 wei
     */
    function withdrawToAddress(address payable _recipient, uint256 _amountInWei) external onlyAdmin {
        require(_amountInWei <= address(this).balance, "Insufficient balance in the contract");
        // 更新用户存款
        deposits[_recipient] -= _amountInWei;
        // 更新前三名
        _updateTopDepositors(_recipient, deposits[_recipient]);
        // 转账
        _recipient.transfer(_amountInWei);
    }

    /**
     * @dev 获取指定地址的存款金额
     * @param _user 要查询存款金额的用户地址
     * @return 指定用户的存款金额，单位为 wei
     */
    function getDeposit(address _user) external view returns (uint256) {
        // 从 deposits 映射中获取指定用户的存款金额并返回
        return deposits[_user];
    }

    /**
     * @dev 获取前 3 名存款用户，调用时进行排序
     * @return 包含前 3 名存款用户信息的结构体数组
     */
    function getTopDepositors() external view returns (UserDeposit[3] memory) {
        return topDepositors;
    }

    // 更新前三名存款用户
    function _updateTopDepositors(address user, uint256 amount) private {
        // 如果金额为0且用户不在前三名中，直接返回
        if (amount == 0) {
            // 检查用户是否在前三名中，如果在则需要移除
            for (uint256 i = 0; i < 3; i++) {
                if (topDepositors[i].user == user) {
                    // 移除该用户
                    topDepositors[i] = UserDeposit(address(0), 0);
                    _sortTopDepositors();
                    break;
                }
            }
            return;
        }

        // 先检查用户是否已经在前三名中
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i].user == user) {
                topDepositors[i].amount = amount;
                _sortTopDepositors();
                return;
            }
        }

        // 如果用户不在前三名中，检查是否应该进入前三名
        // 与每个位置比较，找到合适的插入位置
        for (uint256 i = 0; i < 3; i++) {
            if (amount > topDepositors[i].amount) {
                // 从后向前移动元素
                for (uint256 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j-1];
                }
                // 插入新用户
                topDepositors[i] = UserDeposit(user, amount);
                return;  // 找到位置后直接返回，不需要再排序
            }
        }
    }

    // 对前三名进行排序
    function _sortTopDepositors() private {
        // 优化的排序算法
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = i + 1; j < 3; j++) {
                if (topDepositors[i].amount < topDepositors[j].amount) {
                    UserDeposit memory temp = topDepositors[i];
                    topDepositors[i] = topDepositors[j];
                    topDepositors[j] = temp;
                }
            }
        }
    }
}
