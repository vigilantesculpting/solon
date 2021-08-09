---
exception: nil
fruits/apples/color: 'red'
fruits/apples/count: 5
fruits/oranges/color: 'orange'
fruits/oranges/count: 10
---
%func page: title
<html>
	<head></head>
	<body>
		<title>{{ title }}</title>
		%embed
	</body>
</html>
%end
%wrap page: "Fruit pantry!" 
		<ul>
		%for fruit fruitinfo: fruits iteritems
			%if fruitinfo/count 7 >
				<li>I have {{fruitinfo/count }} {{ fruitinfo/color }} {{ fruit }}</li>
			%else
				<li>I don't have enough {{ fruitinfo/color }} {{ fruit }}</li>
			%end
		%end
		</ul>
%end
---
<html>
	<head></head>
	<body>
		<title>Fruit pantry!</title>
		<ul>
				<li>I don't have enough red apples</li>
				<li>I have 10 orange oranges</li>
		</ul>
	</body>
</html>
