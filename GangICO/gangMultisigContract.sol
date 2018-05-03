pragma solidity ^0.4.22;

contract TokenContract{
    function mint(address _to, uint256 _amount) public;
    function finishMinting () public;
    function setupMultisig (address _address) public;
}

contract CrowdsaleContract{
    function setNewRate (uint _newRate) public;
    function destroyContract () public;
    function setupMultisig (address _address) public;
}

contract GangMultisig {
    
  TokenContract public token;
  CrowdsaleContract public crowdsale;
    
  constructor (address _token, address _crowdsale, uint8 _needApprovesToConfirm, address[] _owners) public{
  	require (_needApprovesToConfirm > 1);
  	
	token = TokenContract(_token);
	crowdsale = CrowdsaleContract(_crowdsale);
	addInitialOwners(_owners);
	needApprovesToConfirm = _needApprovesToConfirm;
	token.setupMultisig(address(this));
	crowdsale.setupMultisig(address(this));
	ownersCount = _owners.length;
  }

  function addInitialOwners (address[] _owners) internal {
  	for (uint i = 0; i < _owners.length; i++){
  	  owners[_owners[i]] = true;
  	}
  }

  mapping (address => bool) owners;

  uint public ownersCount;

  uint public needApprovesToConfirm;

  //Start Minting Tokens
  struct SetNewMint {
    address spender;
    uint value;
    uint8 confirms;
    bool isExecute;
    address initiator;
    mapping (address => bool) confirmators;
  }

  SetNewMint[] public setNewMint;

  event NewMintRequestSetup(address indexed initiator, uint indexed index, address indexed spender, uint value);
  event NewMintRequestUpdate(address indexed owner, uint indexed index, uint8 indexed confirms, bool isExecute);

  function setNewMintRequest (address _spender, uint _value) public {
    require (owners[msg.sender]);

    setNewMint.push(SetNewMint(_spender, _value, 1, false, msg.sender));
    setNewMint[setNewMint.length-1].confirmators[msg.sender] = true;

    emit NewMintRequestSetup(msg.sender, setNewMint.length-1, _spender, _value);
  }

  function approveNewMintRequest (uint index) public {
    require (owners[msg.sender]);

    require (!setNewMint[index].confirmators[msg.sender] && !setNewMint[index].isExecute);
    
    setNewMint[index].confirms++;
    setNewMint[index].confirmators[msg.sender] = true;

    if(setNewMint[index].confirms >= needApprovesToConfirm){
      setNewMint[index].isExecute = true;

      token.mint(setNewMint[index].spender, setNewMint[index].value); 
    }
    emit NewMintRequestUpdate(msg.sender, index, setNewMint[index].confirms, setNewMint[index].isExecute);
  }

  //Finish Minting Tokens

  //Start finishMinting functions

  struct FinishMintingStruct {
    uint8 confirms;
    bool isExecute;
    mapping (address => bool) confirmators;
  }

  FinishMintingStruct public finishMintingStruct;

  event FinishMintingRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event MintFinished();

  bool public mintingFinished = false;

  function finishMinting () public {
    require (owners[msg.sender]);
    require (!finishMintingStruct.isExecute && !finishMintingStruct.confirmators[msg.sender]);
    
    finishMintingStruct.confirmators[msg.sender] = true;

    finishMintingStruct.confirms++;

    if(finishMintingStruct.confirms >= needApprovesToConfirm){
      token.finishMinting();
      finishMintingStruct.isExecute = true;
    }

    emit FinishMintingRequestUpdate(msg.sender, finishMintingStruct.confirms, finishMintingStruct.isExecute);
  }

  //Finish finishMinting functions

  //Start change approves count
  struct SetNewApproves {
    uint count;
    uint8 confirms;
    bool isExecute;
    address initiator;
    mapping (address => bool) confirmators;
  }

  SetNewApproves[] public setNewApproves;

  event NewNeedApprovesToConfirmSetup(address indexed initiator, uint indexed index, uint count);
  event NewNeedApprovesToConfirmUpdate(address indexed owner, uint indexed index, uint8 indexed confirms, bool isExecute);

  function setNewOwnersCountToApprove (uint _count) public {
  	require (_count > 1);
    require (owners[msg.sender]);

    setNewApproves.push(SetNewApproves(_count, 1, false, msg.sender));
    setNewApproves[setNewApproves.length-1].confirmators[msg.sender] = true;

    emit NewNeedApprovesToConfirmSetup(msg.sender, setNewApproves.length-1, _count);
  }

  function approveNewOwnersCount (uint index) public {
    require (owners[msg.sender]);
    require (setNewApproves[index].count <= ownersCount);
    
    require (!setNewApproves[index].confirmators[msg.sender] && !setNewApproves[index].isExecute);
    
    setNewApproves[index].confirms++;
    setNewApproves[index].confirmators[msg.sender] = true;

    if(setNewApproves[index].confirms >= needApprovesToConfirm){
      setNewApproves[index].isExecute = true;

      needApprovesToConfirm = setNewApproves[index].count;   
    }
    emit NewNeedApprovesToConfirmUpdate(msg.sender, index, setNewApproves[index].confirms, setNewApproves[index].isExecute);
  }  
  //Finish change approves count

  //Set rate multisig access
  struct SetRateConfirmation {
    uint rate;
    uint8 confirms;
    bool isExecute;
    address initiator;
    mapping (address => bool) confirmators;
  }

  SetRateConfirmation[] public setRateConfirmation;

  event SetNewRateEvent(address indexed initiator, uint indexed index, uint rate);
  event ApproveSetNewRate(uint indexed index, address indexed owner, uint8 indexed confirms, bool isExecute);

  function setRateInitial (uint256 _rateInWei) public{
    require (owners[msg.sender]);
    setRateConfirmation.push(SetRateConfirmation(_rateInWei, 1, false, msg.sender));
    setRateConfirmation[setRateConfirmation.length-1].confirmators[msg.sender] = true;
    
    emit SetNewRateEvent(msg.sender, setRateConfirmation.length-1, _rateInWei);
  }

  function confirmSetRate (uint index) public {
    require (owners[msg.sender]);
    require (!setRateConfirmation[index].confirmators[msg.sender]);

    setRateConfirmation[index].confirms ++;
    setRateConfirmation[index].confirmators[msg.sender] = true;

    if(setRateConfirmation[index].confirms >= needApprovesToConfirm){
      crowdsale.setNewRate(setRateConfirmation[index].rate);
      setRateConfirmation[index].isExecute = true;
    }

    emit ApproveSetNewRate(index, msg.sender, setRateConfirmation[index].confirms, setRateConfirmation[index].isExecute);
  }
  // End set rate multisig access
  
  // Start DestroyCrowdsaleContract
  event DestroyContractInitial(address indexed initiator);
  event ApproveDestroyContract(address indexed owner, uint8 indexed confirms, bool isExecute);

  struct DestroyContract {
    uint8 confirms;
    bool isExecute;
    address initiator;
    mapping (address => bool) confirmators;
  }

  DestroyContract public destroyContract;

  function destroyContractInitial () public {
    require (owners[msg.sender]);
    if(destroyContract.confirms == 0){
      destroyContract = (DestroyContract(1, false, msg.sender));
      destroyContract.confirmators[msg.sender] = true;
    
      emit DestroyContractInitial(msg.sender);
    }else{
      require (!destroyContract.confirmators[msg.sender] && !destroyContract.isExecute);
      destroyContract.confirms ++;
      destroyContract.confirmators[msg.sender] = true;

      if(destroyContract.confirms >= needApprovesToConfirm){
        destroyContract.isExecute = true;
        emit ApproveDestroyContract(msg.sender, destroyContract.confirms, destroyContract.isExecute);
        
        crowdsale.destroyContract();
      }
    }
  }
  // End DestroyCrowdsaleContract 

  //Start add new owner
  struct NewOwner {
    address newOwner;
    uint8 confirms;
    bool isExecute;
    address initiator;
    mapping (address => bool) confirmators;
  }

  NewOwner[] public newOwners;

  event NewOwnerRequestSetup(address indexed initiator, uint indexed index, address newOwner);
  event NewOwnerRequestUpdate(uint indexed index, address indexed owner, uint8 indexed confirms, bool isExecute);

  function setNewOwnerRequest (address _newOwner) public {
    require (owners[msg.sender]);

    newOwners.push(NewOwner(_newOwner, 1, false, msg.sender));
    newOwners[newOwners.length-1].confirmators[msg.sender] = true;

    emit NewOwnerRequestSetup(msg.sender, newOwners.length-1, _newOwner);
  }

  function approveNewOwnerRequest (uint index) public {
    require (owners[msg.sender]);

    require (!newOwners[index].confirmators[msg.sender] && !newOwners[index].isExecute);
    
    newOwners[index].confirms++;
    newOwners[index].confirmators[msg.sender] = true;

    if(newOwners[index].confirms >= needApprovesToConfirm){
      newOwners[index].isExecute = true;

      owners[newOwners[index].newOwner] = true;
      ownersCount++;
    }
    emit NewOwnerRequestUpdate(index, msg.sender, newOwners[index].confirms, newOwners[index].isExecute);
  }
  //Finish add new owner

  //Start remove owner
  NewOwner[] public removeOwners;

  event RemoveOwnerRequestSetup(address indexed initiator, uint indexed index, address newOwner);
  event RemoveOwnerRequestUpdate(uint indexed index, address indexed owner, uint8 indexed confirms, bool isExecute);

  function removeNewOwnerRequest (address _removeOwner) public {
    require (owners[msg.sender]);

    removeOwners.push(NewOwner(_removeOwner, 1, false, msg.sender));
    removeOwners[removeOwners.length-1].confirmators[msg.sender] = true;

    emit RemoveOwnerRequestSetup(msg.sender, removeOwners.length-1, _removeOwner);
  }

  function approveRemoveOwnerRequest (uint index) public {
    require (owners[msg.sender]);

    require (ownersCount - 1 >= needApprovesToConfirm);
    require (!removeOwners[index].confirmators[msg.sender] && !removeOwners[index].isExecute);
    
    removeOwners[index].confirms++;
    removeOwners[index].confirmators[msg.sender] = true;

    if(removeOwners[index].confirms >= needApprovesToConfirm){
      removeOwners[index].isExecute = true;

      owners[removeOwners[index].newOwner] = true;
      ownersCount--;
    }
    emit RemoveOwnerRequestUpdate(index, msg.sender, removeOwners[index].confirms, removeOwners[index].isExecute);
  }
  //Finish remove owner
}