#!/usr/bin/env bash
## -- vi:ft=sh:

#- preconf
scname="regtry"
desk=$(xdg-user-dir DESKTOP)
base=$desk/${scname}-regex
mkdir $base 2> /dev/null
cd $base
mt_bashrc=$base/bashrc mainbin=$base/main.bash mainconf=$base/main.conf filesbin=$base/files.bash filesconf=$base/files.conf

#- bashrc
cat <<-"EOF0" > bashrc
#!/usr/bin/env bash

# clear alias:
unalias -a

# main conf:
. "${BASH_SOURCE%/*}"/main.conf
# . $mt_regtryset
export PS1="\[\033[00;30;43m\]$scname \[\033[00m\] "
export PATH=$d_command:$HOME/bin/regtry-regex

cd $base

# command:
command_alias(){
    # TODO: Check input
    [[ -d $d_command ]] && /bin/rm -r $d_command/
    /bin/mkdir $d_command

    for k in ${available_commands[@]} ; do
        if [[ ! -L $k ]] ; then
            if type -P /bin/$k &> /dev/null ; then
                /bin/ln -s /bin/$k $d_command/$k
            elif type -P /usr/bin/$k &> /dev/null ; then
                /bin/ln -s /usr/bin/$k $d_command/$k
            else
                echo "ERROR: $k command not found!"
            fi
        fi
    done

    /bin/ln -s /bin/rm $d_command/.dont_use_this

    alias grep="grep --color=always"
}
command_alias

# inspect:
# restricted mode
shopt -q restricted_shell && dar=1 && printf '\033[1;33;40m\n%s\n\033[0m\n' 'You are now in regtry-mode!'

# clean up:
trap ".dont_use_this -r $d_command ; printf '\033[1;33;40m\n%s\n\033[0m\n' 'You checked out of regtry-mode!' " 0
EOF0

#- main.bash
cat <<-"EOF0" > main.bash
#!/usr/bin/env bash

desk=$(xdg-user-dir DESKTOP)
mainconf=./main.conf
# mainconf="${BASH_SOURCE%/*}/main.conf"
. "$mainconf"

# helper:
help() {
    echo "
    options:
        -h | -? | --help  Help.
        -c | --clear      Renew Testfiles.
        -p | --persistent Make files and settings persistent and quit.

    Examples:
        $sc
        $sc --clear
        $sc --help
        $sc --persistent
    "
}

# FILE:
# renew testdir (tfiles) and its content
myclear() {
    # if [ "$1" -eq "$1" ] 2> /dev/null ; then
    if [[ "$1" == 1 ]] ; then
        c=y
    else
        local c
        printf '%s\n%s' "$1" "$2"
        read c
    fi

    if [ $c = y ] ;  then
        printf '%s\n' "testfiles renewed!"
        "$base/./files.bash"
    else
        printf '%s\n' "testfiles not renewed!"
        exit 0
    fi
}

# mypersist
mypersist(){
    # to be able to run from commandline or from menu

    # dirs
    regtrybinpersist="$HOME/.local/bin/regtry-regex/${regtrybin##*/}"
    local dd="${regtrybinpersist%/*}"
    local dm="${regtrydesk%/*}"
    [ ! -d "$dd" ] && mkdir -p "$dd"
    [ ! -d "$dm" ] && mkdir -p "$dm"

    # path
    # if echo $PATH | grep -q "$dd" ; then
    if grep -q "$dd" "$shellconf" ; then
        :
    else
        echo -e "\n# add regtry-regex path to $PATH \nexport PATH=\$PATH:$dd" >> "$shellconf"
    fi

    # bin
    # TODO: delete on "uninstall"
    regtrybinpersist="${regtrybinpersist%.*}"
    [ ! -e "$regtrybinpersist" ] && ln -s "$regtrybin" "${regtrybinpersist}"    # local-dene -> base-main.bash
    # chmod ug+x "$regtrybin"

    # desktop
    [ -e "$regtrydesk" ] && rm "$regtrydesk"
    cat -- > "$regtrydesk" <<EOF
[Desktop Entry]
Name=regtry-regex
Comment=Sets up an restricted shell-environment and testfiles to experiment with regex
Exec=xfce4-terminal --command='bash "$regtrybin"'
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Application;
EOF
}

# ARGUMENTS:
# (( $# <= 0 )) && printf '%s %s\n' "Hint: Use '-h' option to get help:" "$sc -y"

# args
while : ; do
    case $1 in
        -h|-\?|--help)
            help
            exit 0
            ;;
        -c|--clear)
            myclear "Testfiles will renew!" "Do you want to continue? (y/n)"
            shift
            ;;
        -p|--persistent)
            mypersist
            exit 0
            shift
            ;;
        -?*)
            printf 'CANCELLED: Option "%s" unknown!\n' "$1" >&2
            ;;
        *)               # No options left
            break
    esac

    shift
done


# files: renew testfiles
[ ! -d "$d_tfiles" ] && mkdir -p $d_tfiles && myclear 1 && echo "$d_tfiles"

# RESTRICTED:

# restricted shell
/bin/rbash --rcfile "$base/bashrc"
EOF0

#- main.conf
cat <<-"EOF0" > main.conf
#!/usr/bin/env bash

# Desktop
desk=$(xdg-user-dir DESKTOP)
# basepath
export base=$desk/regtry-regex
# available_commands
d_command="$base/komut"
# test files
d_tfiles="$base/tfiles"

# settings
export mainconf="$base/main.conf"
shellconf=$HOME/.bashrc

# bins
regtrybin="$base/main.bash"    # changes on '--mypersist' option
regtrydesk="$HOME/.local/share/applications/regtry-regex.desktop"

# scriptname
sc=$(basename "$BASH_SOURCE")

# COMMAND:
# available commands:
# List of available commands in the regtry-shell. Change it to your needs.
available_commands=(
clear
ls
cat
grep
sed
awk
find
less
more
mkdir
)
EOF0

#- files.bash
cat <<-"EOF0" > files.bash
#!/usr/bin/env bash

# . $regtryset
. ./main.conf

# vars:
dirbase="$base/tfiles"
ctf="$base/files.conf"
lmark=4

# generate files/dirs from yaml-like list
gentry () {

    # TODO: setting in files.conf and here. rewrite!
    # NOTE: each name from files.conf (like car, truck, ship) has to have a setting here. otherwise, SYMTAB[] fails.
    local dm=(
        "-vtruck=the truk is big and heavy."
        "-vbus=the bus is full of people"
        "-vbicycle=the bicycle is healthy and cheap!"
        "-vcar=the car is blue and very fast"
        "-vship=a ship is realy heavy on weight"
        "-vboat=the boat is fast as you may think!"
        "-vyacht=the yacht is comfortable and very very expensive!!"
        "-vmixednames=alfred, daniel, hera, rosa\nbello, asya, mundo"
        "-vnamesa=He\nMan       | 4 | Orko     | 6 | She-ra       | 4 | "
        "-vnamesb=Papa\nSchlumf  | 8 | Schlumpfine      | 4 | schlaubischlumpf   | 7 | "
        "-vemptyfile2="
        )

    mapfile -t comm < <( awk "${dm[@]}" -v dirbase=$dirbase '
    BEGIN{
        FS="[[:space:]:]*$"
    }
    # transliterate `ß` -> `ss`, ` ` -> ``, ...
    function translit(){
        r=""
        split(gensub(/^(.*)\.[^\.]*$/, "\\1", "g", $0), ascii, /[ßüöä[:blank:]]|[^[:alnum:]]/, seps)
        for (as in ascii){
            if(seps[as]!~/[ßüöä]/){
                seps[as]=""
            }
            r = r ascii[as] seps[as]
        }
        c="echo "gensub(/"/, "", "g", r)" | iconv -f utf-8 -t ascii//translit"; while ( c | getline r ){print r }
        return r
    }

    {
        # tab
        gkh=4
        blank=(match($1, /\S/)-1)
        i=int( (blank + (gkh-1)) / gkh )
        # del: leading blanks
        sub(/^[[:space:]]+/, "", $0)
        # string
        s=$1
        if ($0~/^.*:\s*$/){
            # dir
            imk=1; dm=0
        } else {
            imk=0; dm=0

            ddm=translit()

            if(length(ddm)!=0){
                dm=1
                # varname: car, namesa, ...
                varname=ddm
                # varvalue: the car is ..., the ship is ...,
                varval=SYMTAB[ddm]
            }
        }
    }

    {
        # (i)ndent, (l)ast(i)ndent
        if (i==0){
            hamal=dirbase"/"s
        } else if (i==sg){
            sub(/[^\\\/]+[\\\/]*$/, s, hamal)
        } else if (i>sg){
            hamal=hamal"/"s
        } else if (i<sg){
            ks=(sg-i)+1
            hamal=gensub("(/[^/]+){"ks"}$", "", "g", hamal)"/"s
        }
    }

    {
        if (imk==0){
            if (dm==1){
                # filecontent=filecontent" echo \""varname varval"\" > \""hamal"\";"
                filecontent=filecontent" echo \""varval"\" > \""hamal"\";"
            } else {
                dos=dos" \""hamal"\""
            }
        } else {
            dir=dir" \""hamal"\""
        }
        sg=i
    }

    END {
        if(hata!=1){
            system("mkdir -pv " dir)
            #system("touch " dos)
            system(filecontent)
        }

    }
    ' < <(sed '/^#\|^$/d' $ctf)
    )
}
gentry

#-- gen base64 image:
res64 () {
    # base64 vars:
    local res__yellow_50__png='iVBORw0KGgoAAAANSUhEUgAAADIAAAAyAQMAAAAk8RryAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABlBMVEX//wD///+LefOdAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+ICEQsSH/yU4XQAAAAOSURBVBjTY2AYBYMJAAABkAABxZvbSQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wMi0xN1QwODoxODozMSswMzowMH/Go+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDItMTdUMDg6MTg6MzErMDM6MDAOmxtUAAAAAElFTkSuQmCC' res__turquoise3_50__png='iVBORw0KGgoAAAANSUhEUgAAADIAAAAyAQMAAAAk8RryAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABlBMVEUAxc3///8AC86tAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+ICEQsSH/yU4XQAAAAOSURBVBjTY2AYBYMJAAABkAABxZvbSQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wMi0xN1QwODoxODozMSswMzowMH/Go+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDItMTdUMDg6MTg6MzErMDM6MDAOmxtUAAAAAElFTkSuQmCC' res__yellow_100__png='iVBORw0KGgoAAAANSUhEUgAAAGQAAABkAQMAAABKLAcXAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABlBMVEX//wD///+LefOdAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+ICEQsSH/yU4XQAAAAUSURBVDjLY2AYBaNgFIyCUUBPAAAFeAABKXG5/AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wMi0xN1QwODoxODozMSswMzowMH/Go+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDItMTdUMDg6MTg6MzErMDM6MDAOmxtUAAAAAElFTkSuQmCC' res__turquoise3_100__png='iVBORw0KGgoAAAANSUhEUgAAAGQAAABkAQMAAABKLAcXAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABlBMVEUAxc3///8AC86tAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+ICEQsSH/yU4XQAAAAUSURBVDjLY2AYBaNgFIyCUUBPAAAFeAABKXG5/AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wMi0xN1QwODoxODozMSswMzowMH/Go+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDItMTdUMDg6MTg6MzErMDM6MDAOmxtUAAAAAElFTkSuQmCC' res__yellow_50__jpg='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAAyADIDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEBAQEAAAAAAAAAAAAAAAAAAAYJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AoKyqXAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//2Q==' res__turquoise3_50__jpg='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAAyADIDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEBAQEAAAAAAAAAAAAAAAAAAAcJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AurGz3AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf/Z' res__yellow_100__jpg='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCABkAGQDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEBAQEAAAAAAAAAAAAAAAAAAAYJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AoKyqXAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//2Q==' res__turquoise3_100__jpg='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCABkAGQDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEBAQEAAAAAAAAAAAAAAAAAAAcJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AurGz3AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf/Z'

    # varname, varcontent, imagename
    local dis=""  dic="" ris="" rout="$dirbase/images"
    [ ! -d "$rout" ] && mkdir $rout
    for v in ${!res__*} ; do
        dic="${!v}" ; dis=(${v//__/ }) ; ris="${dis[1]}.${dis[2]}" ;
        echo "$dic" | base64 -d --ignore-garbage  > "$rout/$ris"
    done
}
res64
EOF0

#- files.conf
cat <<-"EOF0" > files.conf
# Syntax:
# indent-count == file-level:
#        ➊   ➋   ➌
#       1-4|5-8|9-12| ...
# accepted chars:
#       all chars

vehicles:
    road:
        truck
        car
        bus
        bicycle
    sea:
        boat
        ship
        yacht

# ger-eng-dict:
#     tfiles-source/german-english-dict.txt
#     tfiles-source/book-PeeksAndPokesForTheCommodore64.pdf
#     tfiles-source/book-PeeksAndPokesForTheCommodore64_djvu.txt

names:
    mixed_names
    names_a
    names_b
    empty_file_2
EOF0
#- run
chmod ug+x $mt_bashrc $mainbin $mainconf $filesbin $filesconf
./main.bash
# clear
