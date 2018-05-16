pragma solidity ^0.4.22;

// contract TokenContract{
//     function mint(address _to, uint256 _amount) public;
//     function finishMinting () public;
//     function setupMultisig (address _address) public;
// }

// contract CrowdsaleContract{
//     function setNewRate (uint _newRate) public;
//     function destroyContract () public;
//     function setupMultisig (address _address) public;
// }

contract GangMultisig {
    
//   TokenContract public token;
//   CrowdsaleContract public crowdsale;
    
  constructor (uint8 _needApprovesToConfirm, address[] _owners) public{
    require (_needApprovesToConfirm > 1 && _needApprovesToConfirm <= _owners.length);
  
//    token = TokenContract(_token);

//    crowdsale = CrowdsaleContract(_crowdsale);

    addInitialOwners(_owners);

    needApprovesToConfirm = _needApprovesToConfirm;

//    token.setupMultisig(address(this));
//    crowdsale.setupMultisig(address(this));
    
    ownersCount = _owners.length;
  }

  function addInitialOwners (address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++){
      owners[_owners[i]] = true;
    }
  }

  mapping (address => bool) public owners;

  uint public ownersCount;

  uint public needApprovesToConfirm;

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

    require (ownersCount - 1 >= needApprovesToConfirm && ownersCount > 2);
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