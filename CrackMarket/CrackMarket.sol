pragma solidity ^0.4.19;


/*
    Test data for functions:
    newBounty: "0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", 5
    claimBounty: "0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", ""
    withdrawBounty: "0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
*/

contract CrackMarketSHA256 {
    
    address creator;

    uint constant MINIMAL_DELAY_BEFORE_BOUNTY_WITHDRAWAL = 5; // 5 seconds

    struct Bounty {
        address payer;
        uint payout;
        uint createdAt;
        uint delayInSecondsBeforeWithdrawal;
    }
    
    // Mapped Structs with Index pattern from https://ethereum.stackexchange.com/questions/13167/are-there-well-solved-and-simple-storage-patterns-for-solidity
    mapping(bytes32 => mapping(address => Bounty)) openBounties;
    mapping(bytes32 => address[]) addressesPerHash;
    mapping(bytes32 => uint) bountyPayoutCounter;

    event SuccessfulClaimEvent(address _cracker, uint _payout);
    event FailedClaimEvent(address _cracker);
    event WithdrawEvent(address _payer, bytes32 _hash, uint _payoutLeft);
    
    function CrackMarketSHA256() public { creator = msg.sender; }
    
    // This is here just to play around, in real dapp it shouldn't be as owner can steal funds from bounties
    function kill() public onlyBy(creator) { selfdestruct(creator); }

    // Create new bounty for a hash - same hash can have multiple bounties from different users
    // but a single user can't send multiple bounties for the same hash
    function newBounty(bytes32 hash, uint delay) payable public msgHasValueHigherThan(0.001 ether) {
        // Make sure there is no exinsting bounty for this hash/payer combination

        require(openBounties[hash][msg.sender].payout == 0);
        require(delay >= MINIMAL_DELAY_BEFORE_BOUNTY_WITHDRAWAL);
        // Create new Bounty associated with hash
        openBounties[hash][msg.sender] = Bounty(msg.sender, msg.value, now, delay);
        
        // Increase total bounty counter for this hash
        bountyPayoutCounter[hash] += msg.value;
        
        // Store payer address
        addressesPerHash[hash].push(msg.sender);
    }
    
    function claimBounty(bytes32 hash, string cleartextSolution) public hashHasOpenBounties(hash) {
        var solvedHash = sha256(cleartextSolution);
        
        if (solvedHash == hash) {
            
            var payout = bountyPayoutCounter[hash];

            // Cleanup -- deleting all variables associated with this hash
            // Not sure if this is necessary, but assume bloat from storing
            // old data would be more expensive than this for loop?
            for (uint i = 0; i < addressesPerHash[hash].length; i++) {
                delete openBounties[hash][addressesPerHash[hash][i]];
            }
            delete bountyPayoutCounter[hash];
            delete addressesPerHash[hash];
            
            // Make payment - transfer should throw on failure, reverting cleanup
            msg.sender.transfer(payout);
            SuccessfulClaimEvent(msg.sender, payout);

        } else {
            FailedClaimEvent(msg.sender);
        }
    }
    
    function withdrawBounty(bytes32 hash) public {
        var thisBounty = openBounties[hash][msg.sender];
        
        // Tests if bounty exists and has been in existance for enough time
        require(thisBounty.payout > 0);
        require(now > (thisBounty.createdAt + thisBounty.delayInSecondsBeforeWithdrawal));
        
        var payout = thisBounty.payout;
        
        // Cleanup bounty specific stuff
        bountyPayoutCounter[hash] -= thisBounty.payout;
        delete openBounties[hash][msg.sender];
        
        // Make payment - transfer should throw on failure, reverting cleanup
        msg.sender.transfer(payout);
        
        WithdrawEvent(msg.sender, hash, bountyPayoutCounter[hash]);
    }

    modifier onlyBy(address _account) { require(msg.sender == _account); _; }
    modifier msgHasValueHigherThan(uint _amount) { require(msg.value >= _amount); _; }
    modifier hashHasOpenBounties(bytes32 _hash) { require(bountyPayoutCounter[_hash] > 0); _; }

}
