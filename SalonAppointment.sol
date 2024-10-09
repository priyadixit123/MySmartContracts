// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SalonAppointment {
    struct Appointment {

        address customer;
        uint256 timeSlot;
        string service;
        uint256 price;
        bool isConfirmed;
       }

    address public owner;
    uint256 public servicePrice;
    uint256 public nextAvailablesSlot;
    mapping (uint256 => Appointment) public appointments;
    uint256 public duration = 1 hours;
    uint256 public appointmentId = 0;


    event AppointmentBooked(address indexed customer, uint256 indexed timeSlot, string service);
    event AppointmentCancelled(address indexed customer, uint256 indexed timeSlot);
    event AppointmentCompleted(address indexed customer, uint256 indexed timeSlot);

    

    constructor(uint256 _servicePrice)  {
        owner = msg.sender;
        servicePrice = _servicePrice;
        nextAvailablesSlot = block.timestamp + 1 hours;
    }

    modifier onlyowner () {

        require(
            msg.sender == owner, "Only owner can perform this action");
            _;
    }

    function bookAppointment (string memory service, uint256 timeSlot) public payable 
    {
        require(timeSlot >= nextAvailablesSlot, "No appointments available at that time");
        require(appointments [timeSlot].customer == address(0),"Time Slot is already occupied");
        require(msg.value == servicePrice * 10^18, "Eth amount sent is not equal to price");

        appointments [timeSlot] = Appointment ({
            customer : msg.sender,
            timeSlot : timeSlot,
            service :service,
            price : msg.value,
            isConfirmed : true
        });
        nextAvailablesSlot =timeSlot + duration;
        emit AppointmentBooked(msg.sender, timeSlot, service);
    }  

    function completeAppointment (uint256 timeSlot) public onlyowner 
    {
        require(appointments [timeSlot].isConfirmed == true, "Appointmnet is not confirmed yet");
        require(appointments[timeSlot].customer == msg.sender, "You are not the customer of this appointment");
        payable (owner).transfer(appointments[timeSlot].price);    
        appointments [timeSlot].isConfirmed = false;

        emit AppointmentCompleted(appointments[timeSlot].customer,timeSlot );
        
    }

    function cancelAppointment (uint256 timeSlot) public   
    {
        require(appointments [timeSlot].isConfirmed == true, "Appointmnet is not confirmed yet");
        require(appointments[timeSlot].customer == msg.sender, "You are not the customer of this appointment");
        payable (msg.sender).transfer(appointments[timeSlot].price);    
        delete appointments [timeSlot];

        emit AppointmentCancelled(msg.sender,timeSlot);
        
    }

    function setServicePrice(uint256 _price) onlyowner public {
        servicePrice = _price * 10^18;
    }

    function getNextAvailableSlot()public view onlyowner returns (uint256) 
    {
        return nextAvailablesSlot;
    }

    function getAppointmentDetails(uint256 timeSlot) public view returns (address customer, string memory service, uint256 price, bool isConfirmed) {
    
        Appointment memory app = appointments [timeSlot];
        return (app.customer, app.service, app.price, app.isConfirmed);
    }


}
