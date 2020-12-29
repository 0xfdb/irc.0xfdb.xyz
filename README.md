# irc.0xfdb.xyz
irc.0xfdb.xyz leaf server automated build script

just trying to keep things lazy -

```bash
$ git clone https://github.com/f0ur0ne/irc.0xfdb.xyz.git
$ cd irc.0xfdb.xyz
$ bash ./unrealircd_0xfdb.sh
```

*follow the prompts*


## Example:

- How to spin up a brand new server from nothing on Debian

```bash
$ sudo apt install git base-devel openssl libressl-dev
$ sudo useradd -m irc
$ su irc
$ cd ~
$ git clone https://github.com/f0ur0ne/irc.0xfdb.xyz.git
$ cd irc.0xfdb.xyz
```
copy `example_answerfile.sh` to `answerfile.sh` and fill in the blanks - then:

```bash
$ bash ./unrealircd_0xfdb.sh -f=answerfile.sh --nosudo
```

Hit enter a few times???
