pragma solidity ^0.4.22;

/*@dev abstract token contract
 *to call multisig functions
*/
contract TokenContract{
  function mint(address _to, uint256 _amount) public;
  function finishMinting () public;
  function setupMultisig (address _address) public;
}

/*
 *@title contract GangMultisig
 *@dev using multisig access to call another contract functions
*/
contract GangMultisig {
  
  /*@dev token contract variable, contains token address
   *can use abstract contract functions
  */
  TokenContract public token;
  
  //@dev constructor
  constructor (address _token, uint _needApprovesToConfirm, address[] _owners) public{
    require (_needApprovesToConfirm > 1 && _needApprovesToConfirm <= _owners.length);
    
    //@dev setup GangTokenContract by contract address
    token = TokenContract(_token);

    addInitialOwners(_owners);

    needApprovesToConfirm = _needApprovesToConfirm;

    /*@dev Call function setupMultisig in token contract
     *This function can be call once.
    */
    token.setupMultisig(address(this));
    
    ownersCount = _owners.length;
  }

  /*@dev internal function, called in constructor
   *Add initial owners in mapping 'owners'
  */
  function addInitialOwners (address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++){
      owners[_owners[i]] = true;
    }
  }

  //@dev Variable to check multisig functions life time.
  uint public lifeTime = 300; // seconds;

  //@dev Mapping which contains all active owners.
  mapping (address => bool) public owners;

  //@dev Modifier to check is message sender contains in mapping 'owners'.
  modifier onlyOwners() { 
    require (owners[msg.sender]); 
    _; 
  }

  //@dev current owners count
  uint public ownersCount;

  //@dev current approves need to confirm for any function. Can't be less than 2. 
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

  //@dev Variable which contains all information about current SetNewMint request
  SetNewMint public setNewMint;

  event NewMintRequestSetup(address indexed initiator, address indexed spender, uint value);
  event NewMintRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewMintRequestCanceled();  

  /**
   * @dev Set new mint request, can be call only by owner
   * @param _spender address The address which you want to mint to
   * @param _value uint256 the amount of tokens to be minted
   */
  function setNewMintRequest (address _spender, uint _value) public onlyOwners {
    require (setNewMint.creationTimestamp + lifeTime < uint32(now) || setNewMint.isExecute || setNewMint.isCanceled);

    address[] memory addr;

    setNewMint = SetNewMint(_spender, _value, 1, false, msg.sender, false, uint32(now), addr);
    setNewMint.confirmators.push(msg.sender);

    emit NewMintRequestSetup(msg.sender, _spender, _value);
  }

  /**
   * @dev Approve mint request, can be call only by owner
   * which don't call this mint request before.
   */
  function approveNewMintRequest () public onlyOwners {
    require (!setNewMint.isExecute && !setNewMint.isCanceled);
    require (setNewMint.creationTimestamp + lifeTime >= uint32(now));

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

  /**
   * @dev Cancel mint request, can be call only by owner
   * which created this mint request.
   */
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

  //@dev Variable which contains all information about current finishMintingStruct request
  FinishMintingStruct public finishMintingStruct;

  event FinishMintingRequestSetup(address indexed initiator);
  event FinishMintingRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event FinishMintingRequestCanceled();
  event FinishMintingApproveCanceled(address owner);

  /**
   * @dev New finish minting request, can be call only by owner
   */
  function finishMintingRequestSetup () public onlyOwners{
    require ((finishMintingStruct.creationTimestamp + lifeTime < uint32(now) || !finishMintingStruct.isCanceled) && !finishMintingStruct.isExecute);
    
    address[] memory addr;

    finishMintingStruct = FinishMintingStruct(1, false, msg.sender, false, uint32(now), addr);
    finishMintingStruct.confirmators.push(msg.sender);

    emit FinishMintingRequestSetup(msg.sender);
  }

  /**
   * @dev Approve finish minting request, can be call only by owner
   * which don't call this finish minting request before.
   */
  function ApproveFinishMintingRequest () public onlyOwners {
    require (!finishMintingStruct.isCanceled && !finishMintingStruct.isExecute);
    require (finishMintingStruct.creationTimestamp + lifeTime >= uint32(now));

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
  
  /**
   * @dev Cancel finish minting request, can be call only by owner
   * which created this finish minting request.
   */
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

  //@dev Variable which contains all information about current setNewApproves request
  SetNewApproves public setNewApproves;

  event NewNeedApprovesToConfirmRequestSetup(address indexed initiator, uint count);
  event NewNeedApprovesToConfirmRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewNeedApprovesToConfirmRequestCanceled();

  /**
   * @dev Function to change 'needApprovesToConfirm' variable, can be call only by owner
   * @param _count uint256 New need approves to confirm will needed
   */
  function setNewOwnersCountToApprove (uint _count) public onlyOwners {
    require (setNewApproves.creationTimestamp + lifeTime < uint32(now) || setNewApproves.isExecute || setNewApproves.isCanceled);

    require (_count > 1);

    address[] memory addr;

    setNewApproves = SetNewApproves(_count, 1, false, msg.sender,false, uint32(now), addr);
    setNewApproves.confirmators.push(msg.sender);

    emit NewNeedApprovesToConfirmRequestSetup(msg.sender, _count);
  }

  /**
   * @dev Approve new owners count request, can be call only by owner
   * which don't call this new owners count request before.
   */
  function approveNewOwnersCount () public onlyOwners {
    require (setNewApproves.count <= ownersCount);
    require (setNewApproves.creationTimestamp + lifeTime >= uint32(now));
    
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

  /**
   * @dev Cancel new owners count request, can be call only by owner
   * which created this owners count request.
   */
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
  //@dev Variable which contains all information about current addOwner request

  event AddOwnerRequestSetup(address indexed initiator, address newOwner);
  event AddOwnerRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event AddOwnerRequestCanceled();

  /**
   * @dev Function to add new owner in mapping 'owners', can be call only by owner
   * @param _newOwner address new potentially owner
   */
  function setAddOwnerRequest (address _newOwner) public onlyOwners {
    require (addOwner.creationTimestamp + lifeTime < uint32(now) || addOwner.isExecute || addOwner.isCanceled);
    
    address[] memory addr;

    addOwner = NewOwner(_newOwner, 1, false, msg.sender, false, uint32(now), addr);
    addOwner.confirmators.push(msg.sender);

    emit AddOwnerRequestSetup(msg.sender, _newOwner);
  }

  /**
   * @dev Approve new owner request, can be call only by owner
   * which don't call this new owner request before.
   */
  function approveAddOwnerRequest () public onlyOwners {
    require (!addOwner.isExecute && !addOwner.isCanceled);
    require (addOwner.creationTimestamp + lifeTime >= uint32(now));

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

  /**
   * @dev Cancel new owner request, can be call only by owner
   * which created this add owner request.
   */
  function cancelAddOwnerRequest() public {
    require (msg.sender == addOwner.initiator);
    require (!addOwner.isCanceled && !addOwner.isExecute);

    addOwner.isCanceled = true;
    emit AddOwnerRequestCanceled();
  }
  //Finish add new owner

  //Start remove owner
  NewOwner public removeOwners;
  //@dev Variable which contains all information about current removeOwners request

  event RemoveOwnerRequestSetup(address indexed initiator, address newOwner);
  event RemoveOwnerRequestUpdate(address indexed owner, uint8 indexed confirms, bool isExecute);
  event RemoveOwnerRequestCanceled();

  /**
   * @dev Function to remove owner from mapping 'owners', can be call only by owner
   * @param _removeOwner address potentially owner to remove
  */
  function removeOwnerRequest (address _removeOwner) public onlyOwners {
    require (removeOwners.creationTimestamp + lifeTime < uint32(now) || removeOwners.isExecute || removeOwners.isCanceled);

    address[] memory addr;
    
    removeOwners = NewOwner(_removeOwner, 1, false, msg.sender, false, uint32(now), addr);
    removeOwners.confirmators.push(msg.sender);

    emit RemoveOwnerRequestSetup(msg.sender, _removeOwner);
  }

  /**
   * @dev Approve remove owner request, can be call only by owner
   * which don't call this remove owner request before.
   */
  function approveRemoveOwnerRequest () public onlyOwners {
    require (ownersCount - 1 >= needApprovesToConfirm && ownersCount > 2);
    
    require (!removeOwners.isExecute && !removeOwners.isCanceled);
    require (removeOwners.creationTimestamp + lifeTime < uint32(now));

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

  /**
   * @dev internal function to check and revert all actions
   * by removed owner in this contract.
   * If _oldOwner created request then it will be canceled.
   * If _oldOwner approved request then his approve will canceled.
   */
  function _removeOwnersAproves(address _oldOwner) internal{
    //@dev check actions in setNewMint requests
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
    
    //@dev check actions in finishMintingStruct requests
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

    //@dev check actions in setNewApproves requests
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

    //@dev check actions in addOwner requests
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

    //@dev check actions in removeOwners requests
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

  /**
   * @dev Cancel remove owner request, can be call only by owner
   * which created this remove owner request.
   */
  function cancelRemoveOwnerRequest () public {
    require (msg.sender == removeOwners.initiator);    
    require (!removeOwners.isCanceled && !removeOwners.isExecute);

    removeOwners.isCanceled = true;
    emit RemoveOwnerRequestCanceled();
  }
  //Finish remove owner
}