startっぽいもの
カレントディレクトリ、環境変数をセットしてアプリ起動


start [option] programs
option:
  -e[key=val] 環境変数のセット
  -d[dir]     カレントディレクトリの設定

ex:)
starts.exe "-dc:/Program Files" -eCHERE_INVOKING=yes -eHOME=C:/ "C:\\cygwin\\bin\\mintty.exe -"

