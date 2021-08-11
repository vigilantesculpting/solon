---
exception: nil
name: jack
config/keepComments: True
---
<p>
	hello {{ name }}!
	%- This comment should appear, but the next empty line should not

</p>
---
<p>
	hello jack!
<!-- This comment should appear, but the next empty line should not -->
</p>