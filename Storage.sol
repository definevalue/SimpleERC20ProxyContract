
pragma solidity ^0.5.0;

contract Storage {
    uint public val;
    
   address public implementation;   
    address public owner;
    mapping (address => uint) internal points;
    uint internal totalPlayers;
    
    // for ERC20
    string public constant name = "TNCCoin";
    string public constant symbol = "TNC";
    uint8 public constant decimals = 18;  
    
    //hold the token balance of each owner account.
    mapping(address => uint256) balances;
    
    // mapping object, allowed, will include all of the accounts approved to withdraw from a given account together with the withdrawal sum allowed for each.
    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;
    
    //Deposit related struct
    struct Deposit {
            address _userAddr;
            uint coinsStacked;
            bool isStacked;//need to know the purpose of this field.
            uint256 currentTime;
    }

    //time constraint
    uint cooldownTime =  3 days; // equivalent to 72 hours
    uint32 readyTime;

    // mapping between user address and  the deposit details.
    mapping(address => Deposit) CurrentDeposit;

    //mapping between user address and the deposits made by him in the past. It will be used to store details about all the individual deposits made by the user.
    mapping(address => Deposit[]) userDepositHistory; 
    
    //used to store the withdrawal request.
    struct Request {
            address _userAddr;
            uint coinsToWithdraw;
            bool isConfirmed;
            uint256 dateOfRequest;
            uint coinsApprovedToWithdraw; 
            uint dateOfComfirmationOrRejection; //when the request is confirmed or rejeccted.
            uint dateOfCompletion; // date when transfer was done
            uint32 readyForTransfer;
            bool isCompleted;
    }
    
    mapping(address => Request) currentWithdrawReq;
     //mapping between user address and the deposits made by him in the past. It will be used to store details about all the individual deposits made by the user.
    mapping(address => Request[]) userWithdrawHistory; 
    
    //contains all the user addresses who deposits the token
    address[] userAddresses;
    
    mapping(address => uint) hasActiveTran;
    
 
}
