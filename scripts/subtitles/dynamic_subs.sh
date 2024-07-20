#!/bin/bash

input_file="$1"
output_file="dynamic_subs_${input_file}"

# Check if input file is provided
if [ -z "$input_file" ]; then
    echo "Usage: $0 <input_srt_file>"
    exit 1
fi


printf "Creating dynamic subtitles for %s\n" ${input_file}

temp_file1='temp1.srt'
temp_file2='temp2.srt'
temp_file3='temp3.srt'
temp_file4='temp4.srt'
temp_file5='temp5.srt'


# ╭───────────────────────────────────────────────────────╮
# │            STEP 1 - Remove duplicate lines            │
# ╰───────────────────────────────────────────────────────╯
awk '!seen[$1]++' $input_file > $temp_file1

# ╭───────────────────────────────────────────────────────╮
# │             Step 2 - Remove any newlines              │
# ╰───────────────────────────────────────────────────────╯
sed '/^$/d' $temp_file1 > $temp_file2


# ╭───────────────────────────────────────────────────────╮
# │        Step 2 - Add newlines above each block         │
# ╰───────────────────────────────────────────────────────╯
awk '/^[0-9]+$/{print ""} 1' $temp_file2 > $temp_file3 


# ╭───────────────────────────────────────────────────────╮
# │             Step 3 - Remove blank blocks              │
# ╰───────────────────────────────────────────────────────╯
awk '/^[0-9]+$/{block=$0} /-->/{time=$0; getline; if ($0 != "") print block ORS time ORS $0}' $temp_file3  > $temp_file4


# ╭───────────────────────────────────────────────────────╮
# │        Step 4 - Add newlines above each block         │
# ╰───────────────────────────────────────────────────────╯
awk '/^[0-9]+$/{print ""} 1' $temp_file4 > $temp_file5 


# ╭───────────────────────────────────────────────────────╮
# │           Step 5 - Process lines into words           │
# ╰───────────────────────────────────────────────────────╯
input_file=$temp_file5


# Function to convert timestamp to seconds
timestamp_to_seconds() {
    local timestamp=$1
    

    local h=$(echo $timestamp | cut -d":" -f1)
    local m=$(echo $timestamp | cut -d":" -f2)
    local s=$(echo $timestamp | cut -d":" -f3 | cut -d"," -f1)
    local ms=$(echo $timestamp | cut -d"," -f2)
    
    # Convert milliseconds to seconds
    local ms_seconds=$(echo "scale=3; $ms / 1000" | bc -l)
    
    # Calculate total seconds
    echo "($h * 3600) + ($m * 60) + $s + $ms_seconds" | bc -l
}




# Function to convert seconds back to timestamp format
seconds_to_timestamp() {

    total_seconds=$1

    if [[ "$total_seconds" == "0" ]]; then
        hours=0
        minutes=0
        seconds=0
    else
        # Calculate hours
        hours=$(echo "$total_seconds / 3600" | bc)
        remainder=$(echo "$total_seconds % 3600" | bc)

        # Calculate minutes
        minutes=$(echo "$remainder / 60" | bc)
        remainder=$(echo "$remainder % 60" | bc)

        # Remaining seconds (including fractional part)
        seconds=$(echo "scale=3; $remainder" | bc)

        # Format the output with zero-padding
        printf "%02d:%02d:%06.3f\n" $hours $minutes $seconds
    fi
}





# Read the input file
loop=1
while IFS= read -r line; do

    # ╭───────────────────────────────────────────────────────╮
    # │               If this is a block number               │
    # ╰───────────────────────────────────────────────────────╯
    if [[ $line =~ ^[0-9]+$ ]]; then
        block_number=$line

    # ╭───────────────────────────────────────────────────────╮
    # │                If this is a timestamp                 │
    # ╰───────────────────────────────────────────────────────╯
    elif [[ $line == *"-->"* ]]; then

        # ╭───────────────────────────────────────────────────────╮
        # │         Parse the start / end time from line          │
        # ╰───────────────────────────────────────────────────────╯
        start_time=$(echo "$line" | awk '{print $1}')
        end_time=$(echo "$line" | awk '{print $3}')
        
        # ╭───────────────────────────────────────────────────────╮
        # │ Calculate the amount of time in seconds/milliseconds  │
        # ╰───────────────────────────────────────────────────────╯
        start_seconds=$(timestamp_to_seconds "$start_time")
        end_seconds=$(timestamp_to_seconds "$end_time")
        total_duration=$(echo "scale=10; $end_seconds - $start_seconds" | bc)
        # printf "start_seconds: %s secs \n" $start_seconds
        # printf "end_seconds: %s secs \n" $end_seconds
        # printf "total_duration: %s secs \n" $total_duration
        
        # ╭───────────────────────────────────────────────────────╮
        # │             Count number of words in line             │
        # ╰───────────────────────────────────────────────────────╯
        words=($(IFS=' ' read -ra text; echo "${text[@]:1}"))
        word_count=${#words[@]}
        # printf "number of words: %s \n" $word_count

        # ╭───────────────────────────────────────────────────────╮
        # │  Calculate the amount of time each word should take   │
        # ╰───────────────────────────────────────────────────────╯
        time_per_word=$(echo "scale=4; $total_duration / $word_count" | bc -l)
        # printf "time per word: %s \n" $time_per_word
        

        # Ensure there are words to process
        if [[ $word_count -gt 0 ]]; then

            # Set the initial current_time
            current_time=$start_seconds
            # printf "current_time: %s \n" $current_time

            # ╭───────────────────────────────────────────────────────╮
            # │                loop through each word.                │
            # ╰───────────────────────────────────────────────────────╯
            for (( i=0; i<$word_count; i++ )); do

                # calculate the increment to the next time
                next_time=$(echo "$current_time + $time_per_word" | bc -l)
                # printf "next_time: %s ($current_time + $time_per_word) \n" $next_time

                # Create the timestamps
                current_time_timestamp=$(seconds_to_timestamp $(printf "%.3f" $current_time))
                # printf "current_time_timestamp: %s \n" $current_time_timestamp

                next_time_timestamp=$(seconds_to_timestamp $(printf "%.3f" $next_time))
                # printf "next_time_timestamp: %s \n" $next_time_timestamp

                # output
                printf "%d\n" "$loop"
                printf "%s --> %s\n" "$current_time_timestamp" "$next_time_timestamp"
                printf "%s\n\n" "${words[i]}"

                # Increment the current_time
                current_time=$next_time

                # add to loop
                loop=$(( loop + 1 ))
            done
        else
            # If no words to process, output original block
            printf "%d\n" "$loop"
            printf "%s --> %s\n" "$start_time" "$end_time"
            printf "%s\n\n" "${words[$last]}"
        fi
        
    fi
    
done < "$input_file" > "$output_file"

# cleanup
rm $temp_file1
rm $temp_file2
rm $temp_file3
rm $temp_file4
rm $temp_file5

echo "Deduplication complete. Output saved to $output_file"