---
exception: nil
name: jack
config/keepWhitespace: True
---
<p>
	hello {{ name }}!
	%- This comment should not appear, but the next empty line should

</p>
---
<p>
	hello jack!

</p>