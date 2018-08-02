Konsolechka OpenSourceEdition Docker
--------

Build the image:

```
docker build -t konsolechka .
```

Run the image:

```
docker run -p 4567:4567 konsolechka
```

Run in background:

```
docker run -d -p 4567:4567 konsolechka
```

Access the pidor stats:
- [http://localhost:4567](http://localhost:4567)
- [http://localhost:4567/help/](http://localhost:4567/help/)

