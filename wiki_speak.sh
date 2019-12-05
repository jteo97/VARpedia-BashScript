#!/bin/bash

#this method checks if there are creations in the Creations directory
checkcreations() {
    
	CHECK=`listcreations 2>&1 >/dev/null` #call the listcreations method to check if there are creations in the directory and send stderr and stdout to dev/null
		if [[ "$CHECK" == "ls: cannot access '*.mp4': No such file or directory" ]]; #if the value of the variable is equal to that string go inside the condition
		then 
			echo "no creations have been made"
		fi
		
}

#this method lists the creations in the Creation directory
listcreations() {
	
	cd Creations
	
	ls -1 *.mp4 | sed -e 's/\..*$//' | nl #lists how many creations and removes the suffix ".mp4" and adds line numbers
	
	cd ..
	
}
	
playcreations() {

	cd Creations
	
	ls -1 *.mp4 | sed -e 's/\..*$//' | tee text | nl #lists how many creations and removes the suffix ".mp4" and adds line numbers. Print this to stdout and a text file
	
	read -p "Which Creation do you want to play? Enter the number beside the name of the video" PLAY
	
	MAXCREATIONS=`wc -l < text` #get line count of text file
	while [[ $PLAY -gt $MAXCREATIONS ]] || [[ $PLAY -lt 1 ]]; #check if user has inputed an invalid range number
		do
			read -p "Invalid range specified! Please try again." PLAY
	done
	
	VIDEO=`sed "${PLAY}q;d" text` #store the name of the video that is at the line number the user specified 
	VIDEO=$VIDEO.mp4
	ffplay -autoexit $VIDEO > /dev/null 2>&1 # play the file that matches the name of the video while redirecting stdout and stderr to dev null
	
	rm -f text #tidy up
	cd ..
	
}

deletecreations() {

	cd Creations
	
	ls -1 *.mp4 | sed -e 's/\..*$//' | tee text | nl #lists how many creations and removes the suffix ".mp4" and adds line numbers. Print this to stdout and a text file
	
	read -p "Which Creation would you like to delete? Enter the number beside the name of the video" DELETE
	
	MAXCREATIONS=`wc -l < text` #get line count of text file
	while [[ $DELETE -gt $MAXCREATIONS ]] || [[ $DELETE -lt 1 ]]; #check if user has inputed an invalid range number
		do
			read -p "Invalid range specified! Please try again." DELETE
	done
	
	VIDEO=`sed "${DELETE}q;d" text` #store the name of the video that is at the line number the user specified
	VIDEO=$VIDEO.mp4
	
	read -p "Are you sure you want to delete $VIDEO? y/n" ANS
	case $ANS in
			[yY] | [yY][eE][sS]) #user can input y or yes (lower or upper case)
			rm -f $VIDEO #removes video
		;;
		*) #anything else program does nothing
		;;
		esac
	
	rm -f text #tidy up
	cd ..
	
	read -p "Press enter to continue"
	
}

createcreations() {

	read -p "What term would you like to search on Wikipedia?" SEARCH
	
		
	if [[ `wikit $SEARCH` != "$SEARCH not found :^(" ]]; #search wikipedia for the term and if term is found move on
		then
		
		wikit $SEARCH > wikisearchresults #search wikipedia for the term and saves to text file
		sed 's/\([.?!]\) \([[:upper:]]\)/\1\n\2/g' wikisearchresults > linedresults #Breaks the continuous paragraph to lines according to (.!?)
		nl -nln  -w3 linedresults #number the lines print to stdout
		MAXLINES=`wc -l < linedresults` #store number of lines in text file
		read -p "How many lines would you like to include?" LINES
		while [[ $LINES -gt $MAXLINES ]] || [[ $LINES -lt 1 ]];#check if user has inputed an invalid range number
		do
			read -p "Invalid range specified! Please try again." LINES
		done
		head -n $LINES linedresults > finalresults #take the specified lines from the start and put it in another text file
		text2wave finalresults -o AUDIO.mp3 #send the text file to a text to speech command
		read -p "What name would you like to call your creation?" FINAL
		FINAL=$FINAL.mp4
		cd Creations
		while [[ -f "$FINAL" ]]; #check if file name already exists
		do 
			echo "$FINAL exists"
			read -p "Please enter a different file name:" FINAL
			FINAL=$FINAL.mp4
		done
		cd ..
		seconds=`soxi -D AUDIO.mp3` #retrive the duration of the text to speech file
		ffmpeg -f lavfi -i color=c=blue:s=320x240:d="$seconds" -vf "drawtext=fontfile=Allura-Regular.ttf:fontsize=30:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='$SEARCH'" VIDEO.mp4 > /dev/null 2>&1 #create a video with the term displayed exactly the duration of the text to speech file 
		ffmpeg -i "AUDIO.mp3" -i "VIDEO.mp4" $FINAL > /dev/null 2>&1 #combine the video and audio file into one
		
		mv $FINAL Creations #move creation into the Creations directory
		echo "Creation complete!!!! :)"
		
	else 
		echo "$SEARCH is not found on Wikipedia."
		read -p "Do you want to retry? y/n" ANS
		case $ANS in
			[yY] | [yY][eE][sS]) #user can input y or yes (lower or upper case)
			createcreations #if they pick choose to have a retry then call createcreations again
		;;
		*)
		;;
		esac
	fi
	
	rm -f AUDIO.mp3 VIDEO.mp4 #tidy up
	rm -f finalresults linedresults wikisearchresults #tidy up
	read -p "Press enter to continue"
	
}

quit() {

	read -p "Are you sure? y/n" CHECK
		case $CHECK in
			[yY] | [yY][eE][sS])#user can input y or yes (lower or upper case)
			exit 0 #exit termiinal
		;;
		*) #anything else the program does nothing
		;;
		esac
		
}

main() {

while true; do

#print the menu 
cat << _EOF_

================================================
Welcome to the Wiki-Speak Authoring Tool
================================================
Please select from one of the following options:

	(l)ist existing creations
	(p)lay an existing creations
	(d)elete an existing creations
	(c)reate a new creation
	(q)uit authoring tool
	
_EOF_

read -p "Enter a selection [l/p/d/c/q]: " OPTION
	if [[ ! -e Creations ]]; then #if Creations directory doesn't exist create it
		mkdir Creations
	fi
	
	#case statement to execute different code when user enters a selection
	case $OPTION in 
		"l") 
		if [[ $(checkcreations) == "no creations have been made" ]];
		then 
		echo "There are no creations to be listed out."
		read -p "Please press enter to continue"
		else 		
		listcreations
		read -p "Please press enter to continue"
		fi
		;;
		
		"p")
		if [[ $(checkcreations) == "no creations have been made" ]];
		then 
		echo "There are no creations able to be played."
		read -p "Please press enter to continue"
		else 		
		playcreations
		fi
		;;
		
		"d") 
		if [[ $(checkcreations) == "no creations have been made" ]];
		then 
		echo "There are no creations to be deleted."
		read -p "Please press enter to continue"
		else 		
		deletecreations
		fi
		;;
		
		"c") 
		createcreations
		;;
		
		"q")
		quit
		;;
		
		*)
		echo "Invalid input detected! Please enter one from the selection list"
		read -p "Please press enter to continue"
		;;
	esac
	
done

}

main
