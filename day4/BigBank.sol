// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// IBank 接口定义
interface IBank {
    function withdrawToAddress(address payable _recipient, uint256 _amountInWei) external;
    function getBalance() external view returns (uint256);
}

// Bank 合约
contract Bank is IBank {

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
        admin = msg.sender;
    }

    // 修饰器，仅允许管理员调用使用该修饰器的函数
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * @dev 接收以太币的函数，允许用户直接向合约地址存款
     * 当用户向合约地址发送以太币时，会自动调用该函数
     */
    receive() external payable virtual {
        if (!isUser[msg.sender]) {
            allUsers.push(msg.sender);
            isUser[msg.sender] = true;
        }
        deposits[msg.sender] += msg.value;
    }

    /**
     * @dev 内部函数，用于获取所有有存款的用户地址
     * @return 包含所有有存款用户地址的动态数组
     */
    function getAllUsers() internal view returns (address[] memory) {
        return allUsers;
    }

    /**
     * @dev 管理员提取自定义金额资金到自己账户的函数，输入单位为 wei
     * 只有管理员可以调用该函数
     * @param _amountInWei 管理员要提取的以太币金额，单位为 wei
     */
    function withdrawToSelf(uint256 _amountInWei) external onlyAdmin {
        require(_amountInWei <= address(this).balance, "Insufficient balance in the contract");
        payable(admin).transfer(_amountInWei);
    }

    /**
     * @dev 管理员向指定地址转账自定义金额的函数，输入单位为 wei
     * 只有管理员可以调用该函数
     * @param _recipient 接收转账的地址
     * @param _amountInWei 要转账的以太币金额，单位为 wei
     */
    function withdrawToAddress(address payable _recipient, uint256 _amountInWei) external onlyAdmin  virtual {
        require(_amountInWei <= address(this).balance, "Insufficient balance in the contract");
        _recipient.transfer(_amountInWei);
    }

    /**
     * @dev 获取指定地址的存款金额
     * @param _user 要查询存款金额的用户地址
     * @return 指定用户的存款金额，单位为 wei
     */
    function getDeposit(address _user) external view returns (uint256) {
        return deposits[_user];
    }

    /**
     * @dev 获取前 3 名存款用户，调用时进行排序
     * @return 包含前 3 名存款用户信息的结构体数组
     */
    function getTopDepositors() external view returns (UserDeposit[3] memory) {
        UserDeposit[3] memory top;
        address[] memory userAddresses = getAllUsers();

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address user = userAddresses[i];
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

    /**
     * @dev 获取合约账户以太坊的数量
     * @return 合约账户当前的以太币余额，单位为 wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// BigBank 合约，继承自 Bank
contract BigBank is Bank {

    address public Owner;

    constructor() payable  {
        Owner = msg.sender;
    }

    modifier minimumDeposit() {
        require(msg.value > 0.001 ether, "Deposit amount must be greater than 0.001 ether");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "Only BigBank owner can call this function");
        _;
    }

    // 重写 receive 函数，添加存款金额限制
    receive() external payable minimumDeposit override {
        if (!isUser[msg.sender]) {
            allUsers.push(msg.sender);
            isUser[msg.sender] = true;
        }
        deposits[msg.sender] += msg.value;
    }

    // 转移管理员的函数
    function transferAdmin(address newAdmin) external onlyOwner {
        Owner = newAdmin;
    }

    function withdrawToAddress(address payable _recipient, uint256 _amountInWei) external onlyOwner override {
        require(_amountInWei <= address(this).balance, "Insufficient balance in the BigBank contract");
        _recipient.transfer(_amountInWei);
    }

    // 取款函数
    function adminWithdraw(IBank bank) external onlyOwner {
        uint256 balance = bank.getBalance();
        bank.withdrawToAddress(payable(address(this)), balance);
    }
}

// Admin 合约
contract Admin {
    address public owner;

    constructor() payable  {
        owner = msg.sender;
    }

    // 添加 receive 函数以接收 ETH
    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Admin owner can call this function");
        _;
    }

    function adminWithdraw(IBank bank) external onlyOwner {
        uint256 balance = bank.getBalance();
        bank.withdrawToAddress(payable(address(this)), balance);
    }
}