Hyperfine is needed for benchmark can be installled 
https://github.com/sharkdp/hyperfine
```
apt install hyperfine
```
Edit the binary path in the script Line 13:
`CPX_PATH="$HOME/cpx/cpx"`  # adjust accordingly

also try experimenting(first run with 16 only) the values of -j=num_parallel

Line 132 in bench.sh `"$CPX_PATH -r -j=16 $REPOS_DIR/$name $BENCH_DIR/dest_cpx"`

also Line 153 in bench.sh `"$CPX_PATH -r -j=16 $REPOS_DIR $BENCH_DIR/dest_cpx" `

```
chmod +x ./bench.sh
./bench.sh
```
