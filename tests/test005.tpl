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
%for number: 10 range
	%call do: number
%end
</ul>
---
<ul>
	<li>0</li>
	<li>1</li>
	<li>2</li>
	<li>3</li>
	<li>4</li>

</ul>

