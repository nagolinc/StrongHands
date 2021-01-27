// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";

interface Oracle{
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}


contract StrongHands is IERC20 {
    string public _name;
    string public _symbol;
    uint8  public _decimals;
    
    function name() public view override returns (string memory){
        return _name;
    }
    
    function symbol() public view override  returns (string memory){
        return _symbol;
    }
    
    function decimals() public view override returns (uint8){
        return _decimals;
    }
    
    
    
    IERC20 token;
    Oracle oracle;
    
    mapping (address=>uint256) lastPrice;
    
    function append(string memory a, string memory b) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b));
    
    }
    
    constructor(IERC20 _token, Oracle _oracle) public {
        _name=append("Strong Hands",_token.name());
        _symbol=append("sh",_token.symbol());
        _decimals=_token.decimals();
        token=_token;
        oracle=_oracle;
    }
    
    function onlyHigher(address _address) private{
        uint price=oracle.consult(address(token),10**18);
        require(price>=lastPrice[_address]);
        lastPrice[_address]=price;
    }

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
    
    

    mapping (address => uint)                       public  _balances;
    mapping (address => mapping (address => uint))  public  _allowances;
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function deposit(uint wad) public {
        _balances[msg.sender] += wad;
        require(token.transferFrom(msg.sender,address(this),wad));
        emit Deposit(msg.sender, wad);
    }
    function withdraw(uint wad) public {
        onlyHigher(msg.sender);//can't withdraw unless price increases
        require(_balances[msg.sender] >= wad);
        _balances[msg.sender] -= wad;
        require(token.transfer(msg.sender,wad));
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view override returns (uint) {
        return token.balanceOf(address(this));
    }

    function approve(address guy, uint wad) public override returns (bool) {
        _allowances[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public override returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        override
        returns (bool)
    {
        onlyHigher(src);//can't transfer unless price increases
        require(_balances[src] >= wad);

        if (src != msg.sender && _allowances[src][msg.sender] != uint(-1)) {
            require(_allowances[src][msg.sender] >= wad);
            _allowances[src][msg.sender] -= wad;
        }

        _balances[src] -= wad;
        _balances[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}
