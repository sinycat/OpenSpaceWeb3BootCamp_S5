// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 导入 ERC20 接口
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

contract TokenBank {
    // 记录每个用户在每个代币合约中的存款余额
    mapping(address => mapping(address => uint256)) public balances;
    
    // 存款事件
    event Deposit(address indexed user, address indexed token, uint256 amount);
    // 提款事件
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    
    // 存款函数
    function deposit(address _tokenAddress, uint256 _amount) external {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than 0");
        
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(token.transferFrom(msg.sender, address(this), _amount), "transferFrom failed");
        
        balances[msg.sender][_tokenAddress] += _amount;
        emit Deposit(msg.sender, _tokenAddress, _amount);
    }
    
    // 提款函数
    function withdraw(address _tokenAddress, uint256 _amount) external {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender][_tokenAddress] >= _amount, "withdraw Insufficient balance");
        
        IERC20 token = IERC20(_tokenAddress);
        balances[msg.sender][_tokenAddress] -= _amount;
        require(token.transfer(msg.sender, _amount), "withdraw failed");
        
        emit Withdrawal(msg.sender, _tokenAddress, _amount);
    }
    
    // 查询用户在特定代币合约中的存款余额
    function getBalance(address _user, address _tokenAddress) external view returns (uint256) {
        return balances[_user][_tokenAddress];
    }
    
    // 查询合约中特定代币的总量
    function getTotalBalance(address _tokenAddress) external view returns (uint256) {
        IERC20 token = IERC20(_tokenAddress);
        return token.balanceOf(address(this));
    }
}