pragma solidity ^0.4.22;

contract TokenContract{
    function mint(address _to, uint256 _amount) public;
    function finishMinting () public;
    function setupMultisig (address _address) public;
}

contract GangMultisig {
    
  TokenContract public token;
    
  constructor (address _token, uint _needApprovesToConfirm, address[] _owners) public{
    require (_needApprovesToConfirm > 1 && _needApprovesToConfirm <= _owners.length);
  
    token = TokenContract(_token);

    addInitialOwners(_owners);

    needApprovesToConfirm = _needApprovesToConfirm;

    token.setupMultisig(address(this));
    
    ownersCount = _owners.length;
  }

  function addInitialOwners (address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++){
      owners[_owners[i]] = true;
    }
  }

  mapping (address => bool) public owners;

  modifier onlyOwners() { 
    require (owners[msg.sender]); 
    _; 
  }

  uint public ownersCount;

  uint public needApprovesToConfirm;

  //Start Minting Tokens
  struct SetNewMint {
    address spender;
    uint value;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  SetNewMint public setNewMint;

  event NewMintRequestSetup(address indexed initiator, address indexed spender, uint value);
  event NewMintRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewMintRequestCanceled();  

  function setNewMintRequest (address _spender, uint _value) public onlyOwners {
    require (setNewMint.creationTimestamp + 1 days < uint32(now) || setNewMint.isExecute || setNewMint.isCanceled);

    address[] memory addr;

    setNewMint = SetNewMint(_spender, _value, 1, false, msg.sender, false, uint32(now), addr);
    setNewMint.confirmators.push(msg.sender);

    emit NewMintRequestSetup(msg.sender, _spender, _value);
  }

  function approveNewMintRequest () public onlyOwners {
    require (!setNewMint.isExecute && !setNewMint.isCanceled);

    for (uint i = 0; i < setNewMint.confirmators.length; i++){
      require(setNewMint.confirmators[i] != msg.sender);
    }
      
    setNewMint.confirms++;
    setNewMint.confirmators.push(msg.sender);

    if(setNewMint.confirms >= needApprovesToConfirm){
      setNewMint.isExecute = true;

      token.mint(setNewMint.spender, setNewMint.value); 
    }
    emit NewMintRequestUpdate(msg.sender, setNewMint.confirms, setNewMint.isExecute);
  }

  function cancelMintRequest () public {
    require (msg.sender == setNewMint.initiator);    
    require (!setNewMint.isCanceled && !setNewMint.isExecute);

    setNewMint.isCanceled = true;
    emit NewMintRequestCanceled();
  }
  //Finish Minting Tokens

  //Start finishMinting functions
  struct FinishMintingStruct {
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  FinishMintingStruct public finishMintingStruct;

  event FinishMintingRequestSetup(address indexed initiator);
  event FinishMintingRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event FinishMintingRequestCanceled();
  event FinishMintingApproveCanceled(address owner);

  bool public mintingFinished = false;

  function finishMintingRequestSetup () public onlyOwners{
    require ((finishMintingStruct.creationTimestamp + 1 days < uint32(now) || !finishMintingStruct.isCanceled) && !finishMintingStruct.isExecute);
    
    address[] memory addr;

    finishMintingStruct = FinishMintingStruct(1, false, msg.sender, false, uint32(now), addr);
    finishMintingStruct.confirmators.push(msg.sender);

    emit FinishMintingRequestSetup(msg.sender);
  }

  function ApproveFinishMintingRequest () public onlyOwners {
    require (finishMintingStruct.creationTimestamp + 1 days < uint32(now) && !finishMintingStruct.isCanceled && !finishMintingStruct.isExecute);

    for (uint i = 0; i < finishMintingStruct.confirmators.length; i++){
      require(finishMintingStruct.confirmators[i] != msg.sender);
    }

    finishMintingStruct.confirmators.push(msg.sender);

    finishMintingStruct.confirms++;

    if(finishMintingStruct.confirms >= needApprovesToConfirm){
      token.finishMinting();
      finishMintingStruct.isExecute = true;
    }
    
    emit FinishMintingRequestUpdate(msg.sender, finishMintingStruct.confirms, finishMintingStruct.isExecute);
  }
  
  function cancelFinishMintingRequest () public {
    require (msg.sender == finishMintingStruct.initiator);
    require (!finishMintingStruct.isCanceled);

    finishMintingStruct.isCanceled = true;
    emit FinishMintingRequestCanceled();
  }
  //Finish finishMinting functions

  //Start change approves count
  struct SetNewApproves {
    uint count;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  SetNewApproves public setNewApproves;

  event NewNeedApprovesToConfirmRequestSetup(address indexed initiator, uint count);
  event NewNeedApprovesToConfirmRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewNeedApprovesToConfirmRequestCanceled();

  function setNewOwnersCountToApprove (uint _count) public onlyOwners {
    require (setNewApproves.creationTimestamp + 1 days < uint32(now) || setNewApproves.isExecute || setNewApproves.isCanceled);

    require (_count > 1);

    address[] memory addr;

    setNewApproves = SetNewApproves(_count, 1, false, msg.sender,false, uint32(now), addr);
    setNewApproves.confirmators.push(msg.sender);

    emit NewNeedApprovesToConfirmRequestSetup(msg.sender, _count);
  }

  function approveNewOwnersCount () public onlyOwners {
    require (setNewApproves.count <= ownersCount);
    
    for (uint i = 0; i < setNewApproves.confirmators.length; i++){
        require(setNewApproves.confirmators[i] != msg.sender);
    }
    
    require (!setNewApproves.isExecute && !setNewApproves.isCanceled);
    
    setNewApproves.confirms++;
    setNewApproves.confirmators.push(msg.sender);

    if(setNewApproves.confirms >= needApprovesToConfirm){
      setNewApproves.isExecute = true;

      needApprovesToConfirm = setNewApproves.count;   
    }
    emit NewNeedApprovesToConfirmRequestUpdate(msg.sender, setNewApproves.confirms, setNewApproves.isExecute);
  }

  function cancelNewOwnersCountRequest () public {
    require (msg.sender == setNewApproves.initiator);    
    require (!setNewApproves.isCanceled && !setNewApproves.isExecute);

    setNewApproves.isCanceled = true;
    emit NewNeedApprovesToConfirmRequestCanceled();
  }
  
  //Finish change approves count

  //Start add new owner
  struct NewOwner {
    address newOwner;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    uint32 creationTimestamp;
    address[] confirmators;
  }

  NewOwner public addOwner;

  event AddOwnerRequestSetup(address indexed initiator, address newOwner);
  event AddOwnerRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event AddOwnerRequestCanceled();

  function setAddOwnerRequest (address _newOwner) public onlyOwners {
    require (addOwner.creationTimestamp + 1 days < uint32(now) || addOwner.isExecute || addOwner.isCanceled);
    
    address[] memory addr;

    addOwner = NewOwner(_newOwner, 1, false, msg.sender, false, uint32(now), addr);
    addOwner.confirmators.push(msg.sender);

    emit AddOwnerRequestSetup(msg.sender, _newOwner);
  }

  function approveAddOwnerRequest () public onlyOwners {
    require (!addOwner.isExecute && !addOwner.isCanceled);

    for (uint i = 0; i < addOwner.confirmators.length; i++){
      require(addOwner.confirmators[i] != msg.sender);
    }
    
    addOwner.confirms++;
    addOwner.confirmators.push(msg.sender);

    if(addOwner.confirms >= needApprovesToConfirm){
      addOwner.isExecute = true;

      owners[addOwner.newOwner] = true;
      ownersCount++;
    }

    emit AddOwnerRequestUpdate(msg.sender, addOwner.confirms, addOwner.isExecute);
  }

  function cancelAddOwnerRequest() public {
    require (msg.sender == addOwner.initiator);
    require (!addOwner.isCanceled && !addOwner.isExecute);

    addOwner.isCanceled = true;
    emit AddOwnerRequestCanceled();
  }
  //Finish add new owner

  //Start remove owner
  NewOwner public removeOwners;

  event RemoveOwnerRequestSetup(address indexed initiator, address newOwner);
  event RemoveOwnerRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event RemoveOwnerRequestCanceled();

  function removeOwnerRequest (address _removeOwner) public onlyOwners {
    require (removeOwners.creationTimestamp + 1 days < uint32(now) || removeOwners.isExecute || removeOwners.isCanceled);

    address[] memory addr;
    
    removeOwners = NewOwner(_removeOwner, 1, false, msg.sender, false, uint32(now), addr);
    removeOwners.confirmators.push(msg.sender);

    emit RemoveOwnerRequestSetup(msg.sender, _removeOwner);
  }

  function approveRemoveOwnerRequest () public onlyOwners {
    require (ownersCount - 1 >= needApprovesToConfirm && ownersCount > 2);
    
    require (!removeOwners.isExecute && !removeOwners.isCanceled);

    for (uint i = 0; i < removeOwners.confirmators.length; i++){
      require(removeOwners.confirmators[i] != msg.sender);
    }
    
    removeOwners.confirms++;
    removeOwners.confirmators.push(msg.sender);

    if(removeOwners.confirms >= needApprovesToConfirm){
      removeOwners.isExecute = true;

      owners[removeOwners.newOwner] = false;
      ownersCount--;

      _removeOwnersAproves(removeOwners.newOwner);
    }

    emit RemoveOwnerRequestUpdate(msg.sender, removeOwners.confirms, removeOwners.isExecute);
  }

  function _removeOwnersAproves(address _oldOwner) internal{
    if(setNewMint.initiator == _oldOwner){
      setNewMint.isCanceled = true;
      emit NewMintRequestCanceled();
    }else{
      for (uint i = 0; i < setNewMint.confirmators.length; i++){
        if (setNewMint.confirmators[i] == _oldOwner){
          setNewMint.confirmators[i] = address(0);
          setNewMint.confirms--;

          break;
        }
      }
    }
    
    
    if(finishMintingStruct.initiator == _oldOwner){
      finishMintingStruct.isCanceled = true;
      emit NewMintRequestCanceled();
    }else{
      for (i = 0; i < finishMintingStruct.confirmators.length; i++){
        if (finishMintingStruct.confirmators[i] == _oldOwner){
          finishMintingStruct.confirmators[i] = address(0);
          finishMintingStruct.confirms--;

          break;
        }
      }
    }

    if(setNewApproves.initiator == _oldOwner){
      setNewApproves.isCanceled = true;

      emit NewNeedApprovesToConfirmRequestCanceled();
    }else{
      for (i = 0; i < setNewApproves.confirmators.length; i++){
        if (setNewApproves.confirmators[i] == _oldOwner){
          setNewApproves.confirmators[i] = address(0);
          setNewApproves.confirms--;

          break;
        }
      }
    }

    if(addOwner.initiator == _oldOwner){
      addOwner.isCanceled = true;
      emit AddOwnerRequestCanceled();
    }else{
      for (i = 0; i < addOwner.confirmators.length; i++){
        if (addOwner.confirmators[i] == _oldOwner){
          addOwner.confirmators[i] = address(0);
          addOwner.confirms--;

          break;
        }
      }
    }

    if(removeOwners.initiator == _oldOwner){
      removeOwners.isCanceled = true;
      emit RemoveOwnerRequestCanceled();
    }else{
      for (i = 0; i < removeOwners.confirmators.length; i++){
        if (removeOwners.confirmators[i] == _oldOwner){
          removeOwners.confirmators[i] = address(0);
          removeOwners.confirms--;

          break;
        }
      }
    }
  }

  function cancelRemoveOwnerRequest () public {
    require (msg.sender == removeOwners.initiator);    
    require (!removeOwners.isCanceled && !removeOwners.isExecute);

    removeOwners.isCanceled = true;
    emit RemoveOwnerRequestCanceled();
  }
  //Finish remove owner
}