---
exception: SyntaxError
---
%func do illegal matchlist
	%if matchlist 5 ==
		%exit
	%end
	<li>{{ matchlist }}</li>
%end
---


