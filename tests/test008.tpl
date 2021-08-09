---
exception: nil
---
%func do: number
	%if number 5 ==
		%exit
	%end
	<li>{{ number }}</li>
%end
<ul>
	%call do: 5
</ul>
---
<ul>


