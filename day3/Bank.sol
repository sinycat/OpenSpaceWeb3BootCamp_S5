// SPDX-License-Identifier: MIT
// 指定该合约的许可证为 MIT，这表明代码的使用和分发遵循 MIT 许可证的规定

pragma solidity ^0.8.20;
// 指定 Solidity 编译器的版本，要求编译器版本大于等于 0.8.20 且小于 0.9.0
// 合约已部署到sepolia测试网 合约地址: 0x574108bb2d75AD640719F370A4bB9FA29B36f389
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

    // 记录所有有存款的用户地址
    // 这是一个动态数组，用于存储所有在合约中有存款的用户地址
    address[] public allUsers;

    // 辅助映射，用于快速判断某个地址是否已经在 allUsers 数组中
    // 键为用户地址，值为布尔类型，表示该地址是否为有存款的用户
    mapping(address => bool) public isUser;

    // 用结构体数组记录存款金额的前 3 名用户
    // 每个结构体包含用户地址和对应的存款金额
    struct UserDeposit {
        address user;  // 用户地址
        uint256 amount;  // 用户的存款金额
    }

    /**
     * @dev 构造函数，在合约部署时执行
     * 初始化管理员地址为合约部署者，并设置为 payable 以允许部署时接收以太币
     */
    constructor() payable {
        // 将合约部署者的地址赋值给管理员地址
        admin = msg.sender;
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
        // 检查该用户是否是第一次存款
        if (!isUser[msg.sender]) {
            // 如果是第一次存款，将该用户地址添加到 allUsers 数组中
            allUsers.push(msg.sender);
            // 标记该用户为有存款的用户
            isUser[msg.sender] = true;
        }
        // 更新该用户的存款金额，将本次收到的以太币金额累加到其原有存款上
        deposits[msg.sender] += msg.value;
    }

    /**
     * @dev 内部函数，用于获取所有有存款的用户地址
     * @return 包含所有有存款用户地址的动态数组
     */
    function getAllUsers() internal view returns (address[] memory) {
        // 直接返回存储所有有存款用户地址的数组
        return allUsers;
    }

    /**
     * @dev 管理员提取自定义金额资金到自己账户的函数，输入单位为 wei
     * 只有管理员可以调用该函数
     * @param _amountInWei 管理员要提取的以太币金额，单位为 wei
     */
    function withdrawToSelf(uint256 _amountInWei) external onlyAdmin {
        // 检查合约账户的余额是否足够提取指定金额
        require(_amountInWei <= address(this).balance, "Insufficient balance in the contract");
        // 将指定金额的以太币从合约账户转移到管理员账户
        payable(admin).transfer(_amountInWei);
    }

    /**
     * @dev 管理员向指定地址转账自定义金额的函数，输入单位为 wei
     * 只有管理员可以调用该函数
     * @param _recipient 接收转账的地址
     * @param _amountInWei 要转账的以太币金额，单位为 wei
     */
    function withdrawToAddress(address payable _recipient, uint256 _amountInWei) external onlyAdmin {
        // 检查合约账户的余额是否足够转账指定金额
        require(_amountInWei <= address(this).balance, "Insufficient balance in the contract");
        // 将指定金额的以太币从合约账户转移到指定地址
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
        // 初始化一个长度为 3 的结构体数组，用于存储前 3 名存款用户信息
        UserDeposit[3] memory top;

        // 调用内部函数获取所有有存款的用户地址
        address[] memory userAddresses = getAllUsers();

        // 遍历所有有存款的用户地址
        for (uint256 i = 0; i < userAddresses.length; i++) {
            // 获取当前遍历到的用户地址
            address user = userAddresses[i];
            // 获取该用户的存款金额
            uint256 userDeposit = deposits[user];

            // 遍历 top 数组，找到该用户存款金额应插入的位置
            for (uint256 j = 0; j < 3; j++) {
                // 如果该用户的存款金额大于 top 数组中当前位置的存款金额
                if (userDeposit > top[j].amount) {
                    // 将 top 数组中从 j 位置开始到末尾的元素依次向后移动一位
                    for (uint256 k = 2; k > j; k--) {
                        top[k] = top[k - 1];
                    }
                    // 将该用户的信息插入到 top 数组的 j 位置
                    top[j] = UserDeposit(user, userDeposit);
                    // 插入成功后，跳出内层循环
                    break;
                }
            }
        }

        // 返回存储前 3 名存款用户信息的结构体数组
        return top;
    }

    /**
     * @dev 获取合约账户以太坊的数量
     * @return 合约账户当前的以太币余额，单位为 wei
     */
    function getBalance() external view returns (uint256) {
        // 返回合约账户的当前余额
        return address(this).balance;
    }
}