pragma solidity ^0.4.19;

contract CadasterAndNotary {

    // owner of the contract
    address public owner;

    address public seller;
    address public buyer;

    uint public index;
    uint public price; 
    uint public pricedifference; 
    uint public downpayment; 

    uint public starttime;
    uint public duration;
    uint public endtime;

    uint public sellerprice;
    uint public buyerprice;

    uint public downpaymentbuyer;
    uint public downpaymentseller;

    uint public sellerduration;
    uint public buyerduration;
    
    event PropertyAdded (address seller, uint nrcadastral, uint timeofaquire, bool reserved);
    event AddressAdded (address seller);
    event LogDownPaymentIsSet (address who,uint howmuch);
    event LogAgreedForPreliminary (address who);
    event LogPreliminaryContractInitiated (address buyer, address seller, uint price, uint downpaymentbuyer, uint starttime , uint duration);
    event LogSellerProposal(uint proposedprice, uint proposedduration);
    event LogBuyerProposal (uint proposedprice, uint proposedduration);
    event LogBuyerBalanceIncrease (uint howmuch);
    event LogContractVoided(bool isvoided);
    event LogContractBreaked(address who);
    event LogNewPriceSet(uint howmuch);
    event LogNewDurationSet (uint howmuch);
    event LogAgreementForTransaction(bool agreeementfortransaction);
    event LogTransactionComplete (address buyer, address seller,uint price, uint endtime);
    event LogBalanceIsClaimed (address claimer);
    event Received (address indexed sender, uint value);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyBuyer {
        require (msg.sender == buyer);
        _;
    }
    
    modifier onlySeller {
        require (msg.sender == seller);
        _;
    }
    
    modifier onlyParties {
      require (msg.sender == seller || msg.sender == buyer);
      _;
    }

    mapping (address => bool) public agreedforpreliminary;
    mapping (address => bool) public agreedfortransaction;
    mapping (address => uint) public balances;
    mapping (address => bool) public breakscontract;
    mapping (address => bool) public agreedforvoid;

    // @dev This struct represents a property and it's characteristics
    // should be added: phisical address, size in sqm, topographical coordinates, uPort integration
    struct Property {
    address landlord;

    uint cadasternumber;

    uint timeofaquire;

    bool reserved;

    uint index;
    }

    address[] public landlordarray; // All landlords are stored here.
    Property[] public propertyarray; // All properties are stored here.
    uint public imobilecount; // This is the total number of properties.

    // constructor function
    function CadasterAndNotary() public {
        owner = msg.sender;
    }

    // @dev This function should be used by the cadaster bureau to add new properties
    // @param _landlord The ethereum address of the owner of the property
    // @param _cadasternumber The unique ID of the property called cadasternumber
    // @param _timeofaquire The time that the property was aquired by the current landlord
    // @param _reserved Prevents the landlord from selling the property to multiple parties at the same time
    function addToRecord (address _landlord, uint _cadasternumber, uint _timeofaquire, bool _reserved) public onlyOwner returns (bool success) {

        Property memory init;

        init.landlord = _landlord;
        init.cadasternumber = _cadasternumber;
        init.timeofaquire = _timeofaquire;
        init.reserved = _reserved;      
        imobilecount++;
        init.index = imobilecount - 1; // legit ? check pls
          
        propertyarray.push(init);
        landlordarray.push(_landlord);
                
        return true;
        
        AddressAdded(_landlord);
        PropertyAdded(_landlord, _cadasternumber, _timeofaquire, _reserved);
    }

    // @dev Takes an index as param and returns landlord address, cadasternumber and if the property is reserved
    // @param _atindex Index for which it should return
    function forIndex(uint _atindex) external constant returns (address, uint, bool) {

        return (propertyarray[_atindex].landlord, propertyarray[_atindex].cadasternumber, propertyarray[_atindex].reserved);
   }

   // @dev Takes an index, an adress and a uint as param and returns true if the index matches the address and the uint
   // @param _atindex Index for which it should match
   // @param _landlord The address for which it should match
   // @param _cadasternumber The uint for which it should match
  function isOwner(uint _atindex, address _landlord, uint _cadasternumber) external constant returns(bool isindeed){

        require(propertyarray[_atindex].landlord == _landlord && propertyarray[_atindex].cadasternumber == _cadasternumber );
        return true;
    }

    function initiateTransaction (address _buyer, address _seller, uint _index, uint _price,uint _duration ) public {
      require (msg.sender == propertyarray[_index].landlord);
      require (propertyarray[_index].landlord == _seller);
      require (propertyarray[_index].reserved == false); 

      buyer = _buyer;
      seller = _seller;
      index = _index;
      price = _price;
      duration = _duration;
    }
  
    // @dev downPayment function sets the value which will be held as escrow when preliminaryContract is triggered
    // @param _downpayment The value which either party wishes to set as downpayment
    //  can be called multiple times prior transaction
    // attention: if parties fail to agree on a downpayment the contract just waits for finish and has little effect as downpayment remains zero => no penalties
    function downPayment (uint _downpayment) public payable onlyParties  {
      // overkill
        require (agreedforpreliminary[buyer] == false && agreedforpreliminary[seller] == false);
        require (_downpayment != 0);
        require (_downpayment == msg.value);
        require (_downpayment < price);

        if (msg.sender == buyer)  {

          downpaymentbuyer = _downpayment;
		  balances[buyer] += downpaymentbuyer;
        }
        if (msg.sender == seller) {

		  downpaymentseller = _downpayment;
          balances[seller] += downpaymentseller;
        }

        LogDownPaymentIsSet(msg.sender, _downpayment);
    }

    // @dev When a party calls this it means he/she agrees with the terms. If both parties agree, preliminaryContract is triggered
    function agreementForPreliminary () public onlyParties {
      require (downpaymentseller == downpaymentbuyer);
      require (downpaymentbuyer != 0); // both necessary ?
      require (downpaymentseller != 0);

      if (msg.sender == buyer) {
        agreedforpreliminary[buyer] = true;
        LogAgreedForPreliminary (msg.sender);
      }
      if (msg.sender == seller) {
        agreedforpreliminary[seller] = true;
        LogAgreedForPreliminary (msg.sender);
      }
      if (agreedforpreliminary[buyer] == true && agreedforpreliminary[seller] == true) preliminaryContract();
    }

    // @dev This is the function which actually produces effect and locks the downpayment as escrow
    function preliminaryContract ()  private onlyParties  returns (bool success) {

      // overkill 
        require (agreedforpreliminary[buyer] == true && agreedforpreliminary[seller] == true );
        require (downpaymentseller == downpaymentbuyer);
        require (downpaymentbuyer != 0); // both necessary ?
        require (downpaymentseller != 0);

        require (balances[buyer] == downpaymentbuyer);
        require (balances[buyer] == balances[seller]);
        require (balances[seller] == downpaymentseller);

        starttime = now;
        endtime = starttime + duration;
        propertyarray[index].reserved = true;
        balances[buyer] -= downpaymentbuyer; // legit ?
        balances[seller] -= downpaymentseller;
        pricedifference = price - downpaymentseller; // or downpaymentbuyer
        return true;

        LogPreliminaryContractInitiated (buyer, seller,price, downpaymentbuyer, starttime, duration);
    }

    // @dev Seller can propose diffrent terms for transaction (price and duration)
    // @param _sellerprice The new price proposed by the seller
    // @param _duration The new duration proposed by the seller
    function sellerProposal(uint _sellerprice, uint _sellerduration) public onlySeller  {
      sellerprice = _sellerprice;
      require (_sellerduration > (now - starttime)); // legit ?
      sellerduration = _sellerduration;
      triggerProposals ();

      LogSellerProposal(_sellerprice, _sellerduration);
    }

    // @dev Buyer can propose diffrent terms for transaction (price and duration)
    // @param _buyerprice The new price proposed by the buyer
    // @param _duration The new duration proposed by the buyer
    function buyerProposal(uint _buyerprice, uint _buyerduration) public onlyBuyer  {
      buyerprice = _buyerprice;
      require (_buyerduration > (now - starttime));
      buyerduration = _buyerduration ;
      triggerProposals ();

      LogBuyerProposal(_buyerprice, _buyerduration);
    }

    // @dev This function gets triggered eacht time either party proposes diffrent terms
    //  add event
    function triggerProposals () private onlyParties {

      if (sellerprice == buyerprice && sellerprice != 0 && buyerprice != 0) {
        price = sellerprice; // or price = buyerprice;

        LogNewPriceSet(sellerprice);
      }
      if (sellerduration == buyerduration && sellerduration != 0 && buyerduration != 0) {
        duration = buyerduration; // idem

        LogNewDurationSet(buyerduration);
      }
    }

    // @dev Allows the buyer to incerease his balance so that it has enough funds for transaction
    function increaseBuyerBalance () public payable onlyBuyer  {

      require (agreedfortransaction[buyer] == false);
      if (msg.sender == buyer) balances[buyer] += msg.value;

      LogBuyerBalanceIncrease (msg.value);
    }

    // @dev Either party can call this function, breaking the contract and loosing the downpayment as a penalty
    function disagreementForVoid() public onlyParties {
      // overkill
      require(downpaymentbuyer != 0 && downpaymentseller == downpaymentbuyer && downpaymentseller != 0);
      if (msg.sender == buyer) {
        breakscontract[buyer] = true;
      transaction();

        LogContractBreaked(msg.sender);
      }
      if (msg.sender == seller) {
        breakscontract[seller] = true;
        transaction();

        LogContractBreaked(msg.sender);
      }
    }

    // @dev If both parties agree to void the contract, both receive the downpayment as a refund
    function agreementForVoid () public onlyParties  {
      // overkill
      require(downpaymentbuyer != 0 && downpaymentseller == downpaymentbuyer && downpaymentseller != 0);
      if (msg.sender == buyer) agreedforvoid[buyer] = true;
      if (msg.sender == seller) agreedforvoid[seller] = true;
      if (agreedforvoid[buyer] == true && agreedforvoid[seller] == true) {
      transaction();

        LogContractVoided(true);
      }
    }

    // @dev When a party calls this it means he agrees with the terms. If both agree tranasction is triggered
    function agreementForTransaction () public onlyParties  {
      // overkill
      require(downpaymentbuyer != 0 && downpaymentseller == downpaymentbuyer && downpaymentseller != 0);
      if (msg.sender == buyer) {agreedfortransaction[buyer] = true;}
      if (msg.sender == seller) {agreedfortransaction[seller] = true;}
      if (agreedfortransaction[buyer] == true && agreedfortransaction[seller] == true) {
       transaction();

        LogAgreementForTransaction(true);
      }
    }

    // @dev This is the funcion which resolves the contract either way
    function transaction () private returns (bool transactioncomplete) {

        require(propertyarray[index].reserved == true);
        // overkill
        if (balances[buyer] >= pricedifference && breakscontract[seller] == false && breakscontract[buyer] == false &&
            agreedforvoid[buyer] == false && agreedforvoid[seller] == false) {

              pricedifference = price - downpaymentbuyer; // or downpaymentseller
              balances[buyer] -= pricedifference;
              balances[seller] += pricedifference;
              balances[seller] += downpaymentbuyer + downpaymentseller; 
              propertyarray[index].landlord = buyer;
              propertyarray[index].timeofaquire = now;

        }
        else if (agreedforvoid[buyer] == true && agreedforvoid[seller] == true) {
        //  || (breakscontract[buyer] == true && breakscontract[seller] == true) this should not be possible
            balances[buyer] += downpaymentbuyer;
            balances[seller] += downpaymentseller;
          }

        else if (breakscontract[buyer] == true && breakscontract[seller] == false) {
            balances[seller] += downpaymentbuyer;
        }

        else if (breakscontract[buyer] == false && breakscontract[seller] == true) {
            balances[buyer] += downpaymentseller;
        }

        propertyarray[index].reserved = false;
        return true;

        LogTransactionComplete(seller, buyer, price, endtime);
    }

    // @dev Allows either party to claim it's balance
    function claimBalance(address _claimer)  public {

        require(propertyarray[index].reserved == false);    
        if (_claimer == seller && balances[seller] > 0) {
			       balances[seller] = 0; 
             seller.transfer(balances[seller]);
        }

        if (_claimer == buyer && balances[buyer] > 0) {
			       balances[buyer] = 0;
             buyer.transfer(balances[buyer]);
        }

        LogBalanceIsClaimed (_claimer);
    }

    // @dev fallback function
    function () payable { Received(msg.sender, msg.value); }

    
        // Notable shortcomings:
        // 1. There is no way to loop propertyarray as it would (presumably) be very large and an OOG error would be reached fast.
        // Possible fix: Loop it client-side via events
        // 2.duration is set in seconds, using "now" as a source of time and transaction function does not trigger
        // if duration time expires(and it should).
        // Possible fix: use Ehereum Alarm clock from https://github.com/pipermerriam/ethereum-alarm-clock
        // 3. There is no function for deleting a property    
        // Possible fix: add such a function
        // 4. The cadaster and notary functionality should be split into 2 diffrent contracts.
        // I was not able to do this because structs can only be passed internally as far as I'm aware.

}
