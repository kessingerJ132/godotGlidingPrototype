\# godotGlidingPrototype



A small project I messed around in. I followed BornCG's "Godot 4 Beginners: Learn to make a 3D Platformer!" part way.

I then started experimenting with implementing some features I was interested in playing with.



Link to tutorial series: https://www.youtube.com/playlist?list=PLda3VoSoc\_TTp8Ng3C57spnNkOw3Hm\_35





\# Running it



Download Godot 4.4

Launch project with it

Click "Play Current Scene" while the scene "level\_one" is selected

It's encouraged to enable some debug options under the "Debug" menu option at the top to see hitboxes





\# What I did



I followed BornCG's tutorial until I got a movable character, ability to create a level layout, and learned the basics of GDScript.

Building from BornCG's tutorial, I added an enemy and the ability to attack and glide.



The enemy uses Godot's NavigationRegion3D and NavigationAgent3D to move toward the player. It only moves toward the player if the player is

in its cone of vision and it has line of sight. While moving toward the player it will shoot projectiles at the player. 



Both the enemy and player have a hurt box and the ability to take damage. The enemy disappears once it's been hit enough. There is no

implementation to handle player death.



In addition to basic movement, the player has an attack, charged jump, and glide. Nothing happens while a jump is being charged, but once

charged, the player changes color. The attack has no visible hit box. The glide is inspired by Mario 64 and works similarly.





\# Future Work



Adding menus and a way to handle player death

Adding an animation or visual effect for the player's attack

Improving enemy AI to investigate where the player went after Line of Sight is lost.

