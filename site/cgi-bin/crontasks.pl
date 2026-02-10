print "Gorp";
open CRONTEST,">>crontext2.txt";
print CRONTEST "Admin run at ".time."\n";
close CRONTEST;	