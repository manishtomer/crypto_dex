pragma solidity ^0.4.4;


// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
    // Get the total token supply
    function totalSupply() public view returns (uint256);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public view returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) public returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract FixedSupplyToken is ERC20Interface {

    string public constant symbol = "Fixed";
    string public constant name = "Example Fixed Supply Token";
    uint public constant decimals = 0;
    uint256 _totalSupply = 1000000;

    //Owner of the contract 
    address public owner;

    //Balances for each account 
    mapping (address => uint256) balances;

    //Owner allows the transfer
    mapping (address => mapping (address => uint256)) allowed; 

    //modifier that only allows owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("only owner can do this action");
        }
        _;
    }

    constructor() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    //getter for total supply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    //balances of a particular account 
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    //Transfer the balance from one account to another 
    function transfer(address _to, uint256 _amount) public returns (bool) {
        if (balances[msg.sender] > _amount 
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount; 
            emit Transfer(msg.sender, _to, _amount);
            return true;
        }
        else {
            return false;
        }
    }


}
