# MAM_ID and workdir
* First, you need to create a mam_id token (profile > preferences > security). This must be inserted into *every* script at the very top, as each script checks whether a valid cookie is present and, if not, creates one.
* The scripts often use `/opt/MAM` as the workdir. This can be changed if desired. However, remember to create the directory beforehand using `mkdir`.

# Some words
I like to use [MAM_UnsatisfiedTorrents.sh](https://github.com/mattermatt1337/MAM-Script/blob/main/MAM_UnsatisfiedTorrents.sh) in conjunction with [autobrr](https://github.com/autobrr/autobrr). Once the unsatisfied torrent limit is reached, autobrr does not add the torrent to the client.
