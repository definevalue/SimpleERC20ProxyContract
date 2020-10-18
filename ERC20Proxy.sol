
pragma solidity ^0.5.0;
//pragma experimental ABIEncoderV2;

import './Storage.sol';


contract ERC20Proxy is Storage {
    
       //ERC20 events
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    //other events
    event DepositToken(address _addr, uint tokensDeposited);
    event RequestTokenWithdraw(address _addr, uint tokensToBeWithdrawn);
    event ConfirmWithdrawal(address _addr, uint tokensConfirmedToWithdraw);
    event RejectWithdrawal(address _addr,string msg);
    event TransferAmount(address, uint tokensTransferred, string msg);
    
    using SafeMath for uint256;
    
  
     modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    
    constructor(uint _totalSupply) public {
        require(_totalSupply > 0, "Total supply tokens should be at least greater then zero.");
        totalSupply_ = _totalSupply;
         owner = msg.sender;
    }

    function getOwner() public view returns(address) {
        return owner;
    }
   

   function DepositTokens() public payable returns (bool) { //looks fine.
        
        if(CurrentDeposit[msg.sender].coinsStacked ==0) {
             
              CurrentDeposit[msg.sender] = Deposit({
                _userAddr: msg.sender, //address which deposited the ethers/wei
                coinsStacked: msg.value,
                isStacked: true,
                currentTime: now
            });
        } else  {
             CurrentDeposit[msg.sender] = Deposit({
                _userAddr: msg.sender, //address which deposited the ethers/wei
                coinsStacked: msg.value + CurrentDeposit[msg.sender].coinsStacked ,
                isStacked: true,
                currentTime: now
            });
        }
        
        // to view all the individiual Deposit made by the user.
        userDepositHistory[msg.sender].push(Deposit({
                _userAddr: msg.sender, //address which deposited the ethers/wei
                coinsStacked: msg.value,
                isStacked: true,
                currentTime: now
            }));
        
        // Populating it as a part of ERC20 standard
        if(balances[msg.sender] == 0) {
                balances[msg.sender] = msg.value;
            } else {
                balances[msg.sender] = balances[msg.sender]  + msg.value;
            }
            
        hasActiveTran[msg.sender] = 0;
        emit DepositToken(msg.sender,msg.value);
        

    }
   
   function RequestWithdrawal(uint coinsToWithdraw) public {
       
        //at a time only one withdrawal request can be placed per user.
       require(hasActiveTran[msg.sender] == 0,"has an active transaction");
        
            currentWithdrawReq[msg.sender] = Request({
            _userAddr: msg.sender, //address which deposited the ethers/wei
            coinsToWithdraw: coinsToWithdraw * 1000000000000000000,
            isConfirmed: false,
            dateOfRequest: now,
            coinsApprovedToWithdraw: 0,
            dateOfComfirmationOrRejection : 0,
            //dateOfConfirmation: 0,
            dateOfCompletion: 0,
            readyForTransfer:0,
            isCompleted: false
        });
        
        hasActiveTran[msg.sender] = 1;
        emit RequestTokenWithdraw(msg.sender, coinsToWithdraw * 1000000000000000000);
        
    }
     
  
    function ConfirmRequest(address payable _addr, uint _coinsApprovedToWithdraw) public onlyOwner{
        
        require(CurrentDeposit[_addr].coinsStacked >= _coinsApprovedToWithdraw);
       
        //Note: according to current logic, transaction once rejected cannot be confirmed later
        require(hasActiveTran[_addr] == 1, "No active Request associated with the address to confirm");
            currentWithdrawReq[_addr].coinsApprovedToWithdraw = _coinsApprovedToWithdraw * 1000000000000000000;
            currentWithdrawReq[_addr].dateOfComfirmationOrRejection = now;
            currentWithdrawReq[_addr].isConfirmed = true;
            readyTime = uint32(now + cooldownTime);
            currentWithdrawReq[_addr].readyForTransfer = readyTime; //uint32(now + cooldownTime);
            
            
           // PushToWithdrawHistory(_addr, _coinsApprovedToWithdraw, true);
            emit ConfirmWithdrawal(_addr, _coinsApprovedToWithdraw);
     //   }
        
    }
    
    function RejectRequest(address payable _addr, uint _coinsApprovedToWithdraw, string memory reasonForRejection) public onlyOwner {
        
      //  require(CurrentDeposit[_addr].coinsStacked >= _coinsApprovedToWithdraw);
      //  if(hasActiveTran[_addr] == 1) {
          require(hasActiveTran[_addr] == 1, "No active Request associated with the address to reject");
                currentWithdrawReq[_addr].coinsApprovedToWithdraw = _coinsApprovedToWithdraw * 1000000000000000000; //will be zero
                currentWithdrawReq[_addr].dateOfComfirmationOrRejection = now;
                currentWithdrawReq[_addr].isConfirmed = false;
        
                PushToWithdrawHistory(_addr, _coinsApprovedToWithdraw, false);
                hasActiveTran[msg.sender] = 0;
                emit RejectWithdrawal(_addr, reasonForRejection);
       // }
                
    }

    function PushToWithdrawHistory(address _addr, uint _coinsApprovedToWithdraw, bool _isConfirmed) private {
        
        if(_isConfirmed) {
            userWithdrawHistory[msg.sender].push(Request({ 
                _userAddr : _addr,
                coinsToWithdraw : currentWithdrawReq[_addr].coinsToWithdraw,
                isConfirmed : _isConfirmed,
                dateOfRequest : currentWithdrawReq[_addr].dateOfRequest,
                coinsApprovedToWithdraw : _coinsApprovedToWithdraw,
                dateOfComfirmationOrRejection: now,
                dateOfCompletion : 0,
                readyForTransfer : 0,
                isCompleted: true
            }));
            
        } else {
            userWithdrawHistory[msg.sender].push(Request({ 
                _userAddr : _addr,
                coinsToWithdraw : currentWithdrawReq[_addr].coinsToWithdraw,
                isConfirmed : _isConfirmed,
                dateOfRequest : currentWithdrawReq[_addr].dateOfRequest,
                coinsApprovedToWithdraw : _coinsApprovedToWithdraw,
                //dateOfConfirmation: now,
                dateOfComfirmationOrRejection : 0,
                dateOfCompletion : 0,
                readyForTransfer : 0,
                isCompleted : true
            }));
            
        }

 }


   //will be called by the user once transaction has been confirmed to transfer the money
    function TransferFunds() public returns(string memory) {
        string  memory transferStatus;

     // if (now >= currentWithdrawReq[msg.sender].dateOfComfirmationOrRejection + (3 days * 1 days)) {
          require(now >= currentWithdrawReq[msg.sender].dateOfComfirmationOrRejection + (3 days * 1 days), "Transfer not possible right now. Please try later.User need to wait for at least 72 hours/3 days post confirmation");
      //if(currentWithdrawReq[msg.sender].readyForTransfer >= now) {//  "Need to wait for at least 72 hours/3 days post confirmation"
          
          if(currentWithdrawReq[msg.sender].isConfirmed == true) {
                require(CurrentDeposit[msg.sender].coinsStacked >= currentWithdrawReq[msg.sender].coinsApprovedToWithdraw, "required condition did not matched");
               // require(currentWithdrawReq[msg.sender].isConfirmed == true, "Transfer request has been already rejected by the owner.");
        
                msg.sender.transfer(currentWithdrawReq[msg.sender].coinsApprovedToWithdraw);
                CurrentDeposit[msg.sender].coinsStacked= CurrentDeposit[msg.sender].coinsStacked - currentWithdrawReq[msg.sender].coinsApprovedToWithdraw;
                
                currentWithdrawReq[msg.sender].dateOfCompletion = now;
                
                transferStatus= "Transfer done successfully";
                emit TransferAmount(msg.sender, currentWithdrawReq[msg.sender].coinsApprovedToWithdraw, "Transfer completed");
                hasActiveTran[msg.sender] = 0;
                PushToWithdrawHistory(msg.sender, currentWithdrawReq[msg.sender].coinsApprovedToWithdraw, true);
          }
     // } 
      else {
           transferStatus= "Transfer not possible right now. Please try later.User need to wait for at least 72 hours/3 days post confirmation";
           emit TransferAmount(msg.sender, 0, transferStatus);
      }
      
      return transferStatus;
    } 
    
    /*
    function currentStatus() public view returns(bool) {
        return currentWithdrawReq[msg.sender].isConfirmed;
    }
    
    */
    
    function getContractBalance() public payable returns (uint256) { //test
        return address(this).balance;
    }
   
    //ends
    
      //ERC20  methods
   function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public onlyOwner returns (bool) {
        
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
}


library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

