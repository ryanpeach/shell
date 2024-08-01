build:
    docker build -t rgpeach10/shell:local .

run tag="latest":
    docker run -it --rm -v $HOME:/home/rgpeach10 -w /app rgpeach10/shell:{{tag}}

clean:
    docker image prune -f
    docker container prune -f
    docker system prune -f
    docker volume prune -f