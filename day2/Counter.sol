// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


// 已部署到Sepolia测试网,合约地址: 0x49209fE36A6191F4d5E55f2E9556427A3b8432e4
// Url: https://sepolia.etherscan.io/address/0x49209fe36a6191f4d5e55f2e9556427a3b8432e4
contract Counter {
    // 状态变量 counter，用于存储计数
    uint256 public counter;

    // 构造函数，初始化 counter 为 0
    constructor() {
        counter = 0;
    }

    // get() 方法，用于获取 counter 的当前值
    function get() public view returns (uint256) {
        return counter;
    }

    // add(x) 方法，将传入的参数 x 加到 counter 上
    function add(uint256 x) public {
        counter = counter + x;
    }
}