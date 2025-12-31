To run the CarParking model, 

1. Open terminal from the formal_verification_project folder. 

2. run './run.sh' command fon the terminal. 

3. Once JasperGold opens and has compiled the code, click the prove-all button. 

4. Once JasperGold has proved all properties, all failed properties will have a violation trace which can be viewed by right clicking. 

In the default configuration, the property STOP_RIGHT will have a violation trace the shows the oscillations between the RIGHT_PASS and the STOP states. 


For the modified code, go into the formal_verification_modified folder and the perform steps 1 to 4 again. This time, we do not see any oscillations in the violation trace between RIGHT_PASS and the STOP states. 
