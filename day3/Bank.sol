// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    // 构造函数，初始化管理员地址为合约部署者，设置为 payable 以允许部署时接收以太币
    constructor() payable {
        admin = msg.sender;
    }

    // 修饰器，仅允许管理员调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // 接收以太币的函数，允许直接向合约地址存款
    receive() external payable {
        deposits[msg.sender] += msg.value;
    }

    // 内部函数，获取所有有存款的用户地址
    function getAllUsers() internal view returns (address[] memory) {
        address[] memory tempUsers = new address[](address(this).balance > 0 ? address(this).balance : 1);
        uint256 count = 0;
        for (uint256 i = 0; i < tempUsers.length; i++) {
            address user = address(uint160(i));
            if (deposits[user] > 0) {
                tempUsers[count] = user;
                count++;
            }
        }
        address[] memory users = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            users[i] = tempUsers[i];
        }
        return users;
    }

    // 管理员提取自定义金额资金到自己账户，输入单位为 wei
    function withdrawToSelf(uint256 _amountInWei) external onlyAdmin {
        require(_amountInWei <= address(this).balance, "Insufficient balance in the contract");
        payable(admin).transfer(_amountInWei);
    }

    // 管理员向指定地址转账自定义金额，输入单位为 wei
    function withdrawToAddress(address payable _recipient, uint256 _amountInWei) external onlyAdmin {
        require(_amountInWei <= address(this).balance, "Insufficient balance in the contract");
        _recipient.transfer(_amountInWei);
    }

    // 获取指定地址的存款金额
    function getDeposit(address _user) external view returns (uint256) {
        return deposits[_user];
    }

    // 获取前 3 名存款用户，调用时进行排序
    function getTopDepositors() external view returns (UserDeposit[3] memory) {
        UserDeposit[3] memory top;
        address[] memory allUsers = getAllUsers();

        for (uint256 i = 0; i < allUsers.length; i++) {
            address user = allUsers[i];
            uint256 userDeposit = deposits[user];
            for (uint256 j = 0; j < 3; j++) {
                if (userDeposit > top[j].amount) {
                    for (uint256 k = 2; k > j; k--) {
                        top[k] = top[k - 1];
                    }
                    top[j] = UserDeposit(user, userDeposit);
                    break;
                }
            }
        }

        return top;
    }

    // 获取合约账户以太坊的数量
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}