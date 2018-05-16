pragma solidity ^0.4.22;

contract CrowdsaleContract{
    function setNewRate (uint _newRate) public;
    function destroyContract () public;
    function setupMultisig (address _address) public;
}

contract GangMultisigContract {
	mapping (address => bool) public owners;
	uint public needApprovesToConfirm;
}

contract GangCrowdsaleMultisig {
	CrowdsaleContract public crowdsale;
	GangMultisigContract public multisig;


	constructor (address _crowdsaleAddress, address _multisig) public {
		crowdsale = CrowdsaleContract(_crowdsaleAddress);
		multisig = GangMultisigContract(_multisig);

		crowdsale.setupMultisig(address(this));
	}

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
    	require (multisig.owners(msg.sender));
    	setRateConfirmation.push(SetRateConfirmation(_rateInWei, 1, false, msg.sender));
    	setRateConfirmation[setRateConfirmation.length-1].confirmators[msg.sender] = true;
    
    	emit SetNewRateEvent(msg.sender, setRateConfirmation.length-1, _rateInWei);
  	}

  function confirmSetRate (uint index) public {
    require (multisig.owners(msg.sender));
    require (!setRateConfirmation[index].confirmators[msg.sender] && !setRateConfirmation[index].isExecute);

    setRateConfirmation[index].confirms ++;
    setRateConfirmation[index].confirmators[msg.sender] = true;

    if(setRateConfirmation[index].confirms >= multisig.needApprovesToConfirm()){
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

  function destroyContractRequest () public {
    require (multisig.owners(msg.sender));
    if(destroyContract.confirms == 0){
      destroyContract = (DestroyContract(1, false, msg.sender));
      destroyContract.confirmators[msg.sender] = true;
    
      emit DestroyContractInitial(msg.sender);
    }else{
      require (!destroyContract.confirmators[msg.sender] && !destroyContract.isExecute);
      destroyContract.confirms ++;
      destroyContract.confirmators[msg.sender] = true;

      if(destroyContract.confirms >= multisig.needApprovesToConfirm()){
        destroyContract.isExecute = true;
        emit ApproveDestroyContract(msg.sender, destroyContract.confirms, destroyContract.isExecute);
        
        crowdsale.destroyContract();
      }
    }
  }
  // End DestroyCrowdsaleContract 
}