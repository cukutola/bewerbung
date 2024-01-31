#!/usr/bin/env bash
## -- vi:ft=sh:

## -- evvel
desk=$(xdg-user-dir DESKTOP)
base=$desk/mytry-regex
mkdir $base 2> /dev/null
cd $base
mt_bashrc=$base/bashrc mt_mytrybash=$base/mytry.bash mt_mytryset=$base/mytry.set mt_filesbash=$base/files.bash mt_filesset=$base/files.set

## -- bashrc
cat <<-"EOF0" > bashrc
#!/usr/bin/env bash

# clean set:
unalias -a

# mytry set:
. "${BASH_SOURCE%/*}"/mytry.set
export PS1="\[\033[00;30;43m\]Pardus \[\033[00m\] "
export PATH=$d_command:$HOME/bin/mytry-regex

# ev:
cd $base

# command:
lakap(){
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
                echo "ERROR: $k path of command not found!"
            fi
        fi
    done

    /bin/ln -s /bin/rm $d_command/.dont_use_this

    alias grep="grep --color=always"
}
lakap

# inspect:
# restricted mode
shopt -q restricted_shell && dar=1 && printf '\033[1;33;40m\n%s\n\033[0m\n' 'You are now in mytry-mode!'

# clean up:
trap ".dont_use_this -r $d_command ; printf '\033[1;33;40m\n%s\n\033[0m\n' 'You checked out of mytry-mode!' " 0
EOF0
## -- mytry.bash
cat <<-"EOF0" > mytry.bash
#!/usr/bin/env bash

desk=$(xdg-user-dir DESKTOP)
mytryset=$desk/mytry-regex/mytry.set
# mytryset="${BASH_SOURCE%/*}/mytry.set"
. "$mytryset"

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
    mytrybinpersist="$HOME/.local/bin/mytry-regex/${mytrybin##*/}"
    local dd="${mytrybinpersist%/*}"
    local dm="${mytrydesk%/*}"
    [ ! -d "$dd" ] && mkdir -p "$dd"
    [ ! -d "$dm" ] && mkdir -p "$dm"

    # path
    # if echo $PATH | grep -q "$dd" ; then
    if grep -q "$dd" "$shellset" ; then
        :
    else
        echo -e "\n# add mytry-regex path to $PATH \nexport PATH=\$PATH:$dd" >> "$shellset"
    fi

    # bin
    # TODO: delete on "uninstall"
    mytrybinpersist="${mytrybinpersist%.*}"
    [ ! -e "$mytrybinpersist" ] && ln -s "$mytrybin" "${mytrybinpersist}"    # local-dene -> base-mytry.bash
    # chmod ug+x "$mytrybin"

    # desktop
    [ -e "$mytrydesk" ] && rm "$mytrydesk"
    cat -- > "$mytrydesk" <<EOF
[Desktop Entry]
Name=mytry-regex
Comment=Sets up an restricted shell-environment and testfiles to experiment with regex
Exec=xfce4-terminal --command='bash "$mytrybin"'
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
## -- mytry.set
cat <<-"EOF0" > mytry.set
#!/usr/bin/env bash

# Desktop
desk=$(xdg-user-dir DESKTOP)
# basepath
export base=$desk/mytry-regex
# available_commands
d_command="$base/komut"
# test files
d_tfiles="$base/tfiles"

# settings
export mytryset="$base/mytry.set"
shellset=$HOME/.bashrc

# bins
mytrybin="$base/mytry.bash"    # '--mypersist' opsiyonunda değişir!
mytrydesk="$HOME/.local/share/applications/mytry-regex.desktop"

# scriptname
sc=$(basename "$BASH_SOURCE")

# COMMAND:
# available commands:
# List of available commands in the mytry-shell. Change it to your needs.
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
#
## -- files.bash
cat <<-"EOF0" > files.bash
#!/usr/bin/env bash

. $mytryset

# vars:
dirbase="$base/tfiles"
ctf="$base/files.set"     # isim
lmark=4

# generate files/dirs from yaml-like list
gentry () {

    local dm=(
        "-vberkant=Berkant'ın dosyası"
        "-vdeniz=Deniz'ın dosyası"
        "-vyakup=Yakup'un dosyası"
        "-vkarmaisimler=Aybüke\nAytuğ\nAli\nAyşe\nBerkant\nDeniz\nMuhammed\nMert\nMertcan"
        "-vnamesa=Abid       | 4 | Erkek\nAbidin     | 6 | Erkek\nAbir       | 4 | Erkek\nAbır       | 4 | Erkek\nAbıru      | 5 | "
        "-vnamesb=Babürşah  | 8 | Erkek\nBacı      | 4 | Kız\nBadegül   | 7 | Kız\nBade      | 4 | Kız\nBağdaç    | 6 | "
        "-vtureng=acımak           | 6  | » ache 4 » bepainful 9 » hurt 4\nacındırmak       | 10 | "
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
        c="echo "gensub(/\"/, "", "g", r)" | iconv -f utf-8 -t ascii//translit"; while ( c | getline r ){print r }
        return r
    }

    {
        # tab
        gkh=4
        blank=(match($1, /\S/)-1)
        g=int( (blank + (gkh-1)) / gkh )
        # del: leading blanks
        sub(/^[[:space:]]+/, "", $0)
        # dize
        d=$1
        # im: (im k)lasör
        if ($0~/^.*:\s*$/){
            imk=1; dm=0
        } else {
            imk=0; dm=0

            ddm=translit()

            if(length(SYMTAB[ddm])!=0){
                dm=1
                dmic=SYMTAB[ddm]
            }
        }
    }

    {
        # anahtar: (g)irinti
        if (g==0){
            hamal=dirbase"/"d
        } else if (g==sg){
            sub(/[^\\\/]+[\\\/]*$/, d, hamal)
        } else if (g>sg){
            hamal=hamal"/"d
        } else if (g<sg){
            ks=(sg-g)+1
            hamal=gensub("(/[^/]+){"ks"}$", "", "g", hamal)"/"d
        }
    }

    {
        if (imk==0){
            if (dm==1){
                dosic=dosic" echo \""dmic"\" > \""hamal"\";"
            } else {
                dos=dos" \""hamal"\""
            }
        } else {
            diz=diz" \""hamal"\""
        }
        sg=g
    }

    END {
        if(hata!=1){
            system("mkdir -pv " diz)
            system("touch " dos)
            system(dosic)
        }

    }
    ' < <(sed '/^#\|^$/d' $ctf)
    )
}
gentry

# base64 resim:
res64 () {
    # base64 vars:
    local res__yellow_50__png='iVBORw0KGgoAAAANSUhEUgAAADIAAAAyAQMAAAAk8RryAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABlBMVEX//wD///+LefOdAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+ICEQsSH/yU4XQAAAAOSURBVBjTY2AYBYMJAAABkAABxZvbSQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wMi0xN1QwODoxODozMSswMzowMH/Go+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDItMTdUMDg6MTg6MzErMDM6MDAOmxtUAAAAAElFTkSuQmCC' res__turquoise3_50__png='iVBORw0KGgoAAAANSUhEUgAAADIAAAAyAQMAAAAk8RryAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABlBMVEUAxc3///8AC86tAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+ICEQsSH/yU4XQAAAAOSURBVBjTY2AYBYMJAAABkAABxZvbSQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wMi0xN1QwODoxODozMSswMzowMH/Go+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDItMTdUMDg6MTg6MzErMDM6MDAOmxtUAAAAAElFTkSuQmCC' res__yellow_100__png='iVBORw0KGgoAAAANSUhEUgAAAGQAAABkAQMAAABKLAcXAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABlBMVEX//wD///+LefOdAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+ICEQsSH/yU4XQAAAAUSURBVDjLY2AYBaNgFIyCUUBPAAAFeAABKXG5/AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wMi0xN1QwODoxODozMSswMzowMH/Go+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDItMTdUMDg6MTg6MzErMDM6MDAOmxtUAAAAAElFTkSuQmCC' res__turquoise3_100__png='iVBORw0KGgoAAAANSUhEUgAAAGQAAABkAQMAAABKLAcXAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAABlBMVEUAxc3///8AC86tAAAAAWJLR0QB/wIt3gAAAAd0SU1FB+ICEQsSH/yU4XQAAAAUSURBVDjLY2AYBaNgFIyCUUBPAAAFeAABKXG5/AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxOC0wMi0xN1QwODoxODozMSswMzowMH/Go+gAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTgtMDItMTdUMDg6MTg6MzErMDM6MDAOmxtUAAAAAElFTkSuQmCC' res__yellow_50__jpg='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAAyADIDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEBAQEAAAAAAAAAAAAAAAAAAAYJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AoKyqXAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//2Q==' res__turquoise3_50__jpg='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCAAyADIDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEBAQEAAAAAAAAAAAAAAAAAAAcJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AurGz3AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf/Z' res__yellow_100__jpg='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCABkAGQDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEBAQEAAAAAAAAAAAAAAAAAAAYJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AoKyqXAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//2Q==' res__turquoise3_100__jpg='/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/wAARCABkAGQDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFgEBAQEAAAAAAAAAAAAAAAAAAAcJ/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AurGz3AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf/Z'

    # değişken ismi, değişken içeriği, resim ismi
    local dis=""  dic="" ris="" rout="$dirbase/resim"
    [ ! -d "$rout" ] && mkdir $rout
    for v in ${!res__*} ; do
        dic="${!v}" ; dis=(${v//__/ }) ; ris="${dis[1]}.${dis[2]}" ;
        echo "$dic" | base64 -d --ignore-garbage  > "$rout/$ris"
    done
}
res64
EOF0
## -- files.set
cat <<-"EOF0" > files.set
# Syntax:
# indent-count == file-level:
#        ➊   ➋   ➌
#       1-4|5-8|9-12| ...
# accepted chars:
#       all chars

persons (by year):
    2018:
        berkant
        deniz
        yakup
    2017:
        berkant
        deniz
        yakup

türkçe ingilizce:
    tur-eng.txt

names:
    mixed names.txt
    names a.txt
    names b.txt
    empty file 2.txt
EOF0
## -- ahir
chmod ug+x $mt_bashrc $mt_mytrybash $mt_mytryset $mt_filesbash $mt_filesset
./mytry.bash
# clear
