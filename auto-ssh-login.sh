cat ~/.ssh/id_rsa.pub | ssh $1@$2 'cat > temp && mkdir -p .ssh && cd .ssh && touch authorized_keys && cat ../temp >> authorized_keys && rm ../temp'
