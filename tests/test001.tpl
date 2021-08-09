---
exception: nil
fruits/apples/color: 'red'
fruits/apples/count: 5
fruits/oranges/color: 'orange'
fruits/oranges/count: 10
---
<ul>
	%for fruit fruitinfo: fruits iteritems
		%if fruitinfo/count 7 >
			<li>I have enough {{ fruitinfo/color }} {{ fruit }}</li>
		%else
			<li>I don't have enough {{ fruitinfo/color }} {{ fruit }}</li>
		%end
	%end
</ul>
---
<ul>
			<li>I don't have enough red apples</li>
			<li>I have enough orange oranges</li>
</ul>
