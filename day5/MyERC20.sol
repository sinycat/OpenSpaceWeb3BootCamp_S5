// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ERC20基础合约
contract BaseERC20 {
    
    // 代币名称
    string public name; 
    // 代币符号
    string public symbol; 
    // 小数位数
    uint8 public decimals; 
    // 代币总供应量
    uint256 public totalSupply; 

    // 用户余额映射: 地址 => 余额
    mapping (address => uint256) balances; 
    // 授权额度映射: 所有者地址 => (授权地址 => 授权金额)
    mapping (address => mapping (address => uint256)) allowances; 

    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(){
        // 初始化代币基本信息
        name = "BaseERC20";          // 设置代币名称
        symbol = "BERC20";           // 设置代币符号
        decimals = 18;               // 设置小数位数为18
        totalSupply = 100000000 * (10 ** uint256(decimals));  // 设置总供应量为1亿
        balances[msg.sender] = totalSupply;  // 初始供应量全部分配给合约部署者
    }

    // 添加零地址检查修饰器
    modifier validAddress(address _addr) {
        require(_addr != address(0), "ERC20: invalid zero address");
        _;
    }

    // 添加0金额检查修饰器
    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "ERC20: amount must be greater than 0");
        _;
    }

    // 添加余额检查修饰器
    modifier hasEnoughBalance(address _sender, uint256 _value) {
        require(balances[_sender] >= _value, "ERC20: transfer amount exceeds balance");
        _;
    }

    // 添加授权额度检查修饰器
    modifier hasEnoughAllowance(address _owner, address _spender, uint256 _value) {
        require(allowances[_owner][_spender] >= _value, "ERC20: insufficient allowance");
        _;
    }

    // 查询指定地址的代币余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // 转账函数
    function transfer(address _to, uint256 _value) public 
        validAddress(_to) 
        validAmount(_value)
        hasEnoughBalance(msg.sender, _value) 
        returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    // 授权转账函数
    function transferFrom(address _from, address _to, uint256 _value) public 
        validAddress(_from)
        validAddress(_to) 
        validAmount(_value)
        hasEnoughBalance(_from, _value)
        hasEnoughAllowance(_from, msg.sender, _value)
        returns (bool success) {
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    // 授权函数
    function approve(address _spender, uint256 _value) public 
        validAddress(_spender)
        returns (bool success) {
        // 设置授权额度
        allowances[msg.sender][_spender] = _value;
        // 触发授权事件
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    // 查询授权额度
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        return allowances[_owner][_spender];
    }

    // 增加授权额度函数
    function increaseAllowance(address _spender, uint256 _addedValue) public 
        validAddress(_spender)
        validAmount(_addedValue)
        returns (bool) {
        uint256 newAllowance = allowances[msg.sender][_spender] + _addedValue;
        allowances[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        return true;
    }

    // 减少授权额度函数
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public 
        validAddress(_spender)
        validAmount(_subtractedValue)
        hasEnoughAllowance(msg.sender, _spender, _subtractedValue)
        returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        allowances[msg.sender][_spender] = currentAllowance - _subtractedValue;
        emit Approval(msg.sender, _spender, currentAllowance - _subtractedValue);
        return true;
    }
}