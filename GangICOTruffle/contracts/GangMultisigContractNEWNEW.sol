pragma solidity ^0.4.22;

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

  //Start change approves count
  struct SetNewApproves {
    uint count;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    mapping (address => bool) confirmators;
    address[] confirmatorsArray;
  }

  SetNewApproves[] public setNewApproves;

  event NewNeedApprovesToConfirmSetup(address indexed initiator, uint indexed index, uint count);
  event NewNeedApprovesToConfirmUpdate(address indexed owner, uint indexed index, uint8 indexed confirms, bool isExecute);
  event NewNeedApprovesToConfirmRequestCancel(uint index);
  event NewNeedApprovesToConfirmApproveCancel(uint indexed index, address owner);
  

  function setNewOwnersCountToApprove (uint _count) public onlyOwners {
    require (_count > 1);

    setNewApproves.push(SetNewApproves(_count, 1, false, msg.sender,false));
    setNewApproves[setNewApproves.length-1].confirmators[msg.sender] = true;

    emit NewNeedApprovesToConfirmSetup(msg.sender, setNewApproves.length-1, _count);
  }

  function approveNewOwnersCount (uint index) public onlyOwners {
    require (setNewApproves[index].count <= ownersCount);
    
    require (!setNewApproves[index].confirmators[msg.sender] && !setNewApproves[index].isExecute && !setNewApproves[index].isCanceled);
    
    setNewApproves[index].confirms++;
    setNewApproves[index].confirmators[msg.sender] = true;

    if(setNewApproves[index].confirms >= needApprovesToConfirm){
      setNewApproves[index].isExecute = true;

      needApprovesToConfirm = setNewApproves[index].count;   
    }
    emit NewNeedApprovesToConfirmUpdate(msg.sender, index, setNewApproves[index].confirms, setNewApproves[index].isExecute);
  }

  function cancelNewOwnersCountRequest (uint index) public {
    require (msg.sender == setNewApproves[index].initiator);    
    require (!setNewApproves[index].isCanceled);

    setNewApproves[index].isCanceled = true;
    emit NewNeedApprovesToConfirmRequestCancel(index);
  }

  function cancelNewOwnersCountApprove (uint index) public {
    require (setNewApproves[index].confirmators[msg.sender] && !setNewApproves[index].isExecute);
    setNewApproves[index].confirmators[msg.sender] = false;
    setNewApproves[index].confirms--;
    emit NewNeedApprovesToConfirmApproveCancel(index, msg.sender);
  }

  function executeNewOwnersCount (uint index) public {
    
  }
  
  function tryToExecuteNewOwnersCount (uint index) public view returns (bool) {
    uint res = 0;
    for (uint i = 0; i < setNewApproves.confirmatorsArray.length; i++){
      if(owners[setNewApproves.confirmatorsArray[i]]){
        res++;
      }
    }
    if (res >= needApprovesToConfirm){
      return true;
    }
    return false;
  }
  
  
  
  //Finish change approves count

  //Start add new owner
  struct NewOwner {
    address newOwner;
    uint8 confirms;
    bool isExecute;
    address initiator;
    bool isCanceled;
    mapping (address => bool) confirmators;
  }

  NewOwner[] public newOwners;

  event NewOwnerRequestSetup(address indexed initiator, uint indexed index, address newOwner);
  event NewOwnerRequestUpdate(uint indexed index, address indexed owner, uint8 indexed confirms, bool isExecute);
  event NewOwnerRequestCancel(uint index);
  event NewOwnerApproveCancel(uint indexed index, address owner);

  function setNewOwnerRequest (address _newOwner) public onlyOwners {
    newOwners.push(NewOwner(_newOwner, 1, false, msg.sender, false));
    newOwners[newOwners.length-1].confirmators[msg.sender] = true;

    emit NewOwnerRequestSetup(msg.sender, newOwners.length-1, _newOwner);
  }

  function approveNewOwnerRequest (uint index) public onlyOwners {
    require (!newOwners[index].confirmators[msg.sender] && !newOwners[index].isExecute && !newOwners[index].isCanceled);
    
    newOwners[index].confirms++;
    newOwners[index].confirmators[msg.sender] = true;

    if(newOwners[index].confirms >= needApprovesToConfirm){
      newOwners[index].isExecute = true;

      owners[newOwners[index].newOwner] = true;
      ownersCount++;
    }
    emit NewOwnerRequestUpdate(index, msg.sender, newOwners[index].confirms, newOwners[index].isExecute);
  }

  function cancelNewOwnerRequest(uint index) public {
    require (msg.sender == newOwners[index].initiator);    
    require (!newOwners[index].isCanceled);

    newOwners[index].isCanceled = true;
    NewOwnerRequestCancel(index);
  }

  function cancelNewOwnerApprove (uint index) public {
    require (newOwners[index].confirmators[msg.sender] && !newOwners[index].isExecute);
    newOwners[index].confirmators[msg.sender] = false;
    newOwners[index].confirms--;
    NewOwnerApproveCancel(index, msg.sender);
  }
  //Finish add new owner


















  //Start remove owner
  NewOwner[] public removeOwners;

  event RemoveOwnerRequestSetup(address indexed initiator, uint indexed index, address newOwner);
  event RemoveOwnerRequestUpdate(uint indexed index, address indexed owner, uint8 indexed confirms, bool isExecute);


  function removeOwnerRequest (address _removeOwner) public {
    require (owners[msg.sender]);

    removeOwners.push(NewOwner(_removeOwner, 1, false, msg.sender, false));
    removeOwners[removeOwners.length-1].confirmators[msg.sender] = true;

    emit RemoveOwnerRequestSetup(msg.sender, removeOwners.length-1, _removeOwner);
  }

  function approveRemoveOwnerRequest (uint index) public onlyOwners {
    require (ownersCount - 1 >= needApprovesToConfirm && ownersCount > 2);
    require (!removeOwners[index].confirmators[msg.sender] && !removeOwners[index].isExecute && !removeOwners[index].isCanceled);
    
    removeOwners[index].confirms++;
    removeOwners[index].confirmators[msg.sender] = true;

    if(removeOwners[index].confirms >= needApprovesToConfirm){
      removeOwners[index].isExecute = true;

      owners[removeOwners[index].newOwner] = false;
      ownersCount--;

      _removeOwnersAproves(removeOwners[index].newOwner);
    }
    emit RemoveOwnerRequestUpdate(index, msg.sender, removeOwners[index].confirms, removeOwners[index].isExecute);
  }

  function _removeOwnersAproves(address _oldOwner) internal{
    for (uint i = 0; i < setNewMint.length; i++){
      if (setNewMint[i].confirmators[_oldOwner] && !setNewMint[i].isExecute){
        if(setNewMint[i].initiator == _oldOwner){
          setNewMint[i].isCanceled = true;
        }
        setNewMint[i].confirmators[_oldOwner] = false;
        setNewMint[i].confirms--;
      }
    }

    if (finishMintingStruct.confirmators[_oldOwner] && !finishMintingStruct.isExecute){
      finishMintingStruct.confirmators[_oldOwner] = false;
      finishMintingStruct.confirms--;
    }

    for (i = 0; i < setNewApproves.length; i++){
      if (setNewApproves[i].confirmators[_oldOwner] && !setNewApproves[i].isExecute){
        if(setNewApproves[i].initiator == _oldOwner){
          setNewApproves[i].isCanceled = true;
        }
        setNewApproves[i].confirmators[_oldOwner] = false;
        setNewApproves[i].confirms--;
      }
    }

    for (i = 0; i < newOwners.length; i++){
      if (newOwners[i].confirmators[_oldOwner] && !newOwners[i].isExecute){
        if(newOwners[i].initiator == _oldOwner){
          newOwners[i].isCanceled = true;
        }
        newOwners[i].confirmators[_oldOwner] = false;
        newOwners[i].confirms--;
      }
    }

    for (i = 0; i < removeOwners.length; i++){
      if (removeOwners[i].confirmators[_oldOwner] && !removeOwners[i].isExecute){
        if(removeOwners[i].initiator == _oldOwner){
          removeOwners[i].isCanceled = true;
        }
        removeOwners[i].confirmators[_oldOwner] = false;
        removeOwners[i].confirms--;
      }
    }
  }

  function cancelRemoveOwnerRequest (uint index) public {
    require (msg.sender == removeOwners[index].initiator);    
    require (!removeOwners[index].isCanceled);

    removeOwners[index].isCanceled = true;
  }

  function cancelRemoveOwnerApprove (uint index) public {
    require (removeOwners[index].confirmators[msg.sender] && !removeOwners[index].isExecute);
    removeOwners[index].confirmators[msg.sender] = false;
    removeOwners[index].confirms--;
  }
  //Finish remove owner
}