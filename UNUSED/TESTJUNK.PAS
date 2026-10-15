program aa;

uses dm6000;

var
  y,m,d,a,b,c,w: Word;
  temp:string;
  vd: Longint;
begin
  datetoday(w,'01-02-03');
  writeln(presentday,' ',w);
  daytodate(w,temp);
  writeln(temp);
end.