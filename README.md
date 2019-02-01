# CIS 566 Homework 1: Noisy Terrain

## Steven Galban, PennKey: sgalban

![](img/ss1.png)

## Terrain
- My terrain was broken up into 3 different biomes. While I initially planned to have more
that were to be determined using moisture and temperature, time constraints forced me to
use just the 3, which are placed with a one dimensional moisture value. This moisture is generated
through a simple perlin noise function and a qunitic falloff
  - Deserts are found in areas of low moisture. They are fairly flat, with subtle dunes made from
  fractal perlin noise. However, the occasional mesa can also be found. They're generated from fractal
  brownian motion that goes through an incredibly steep falloff that minimizes low values but gives high
  values a flat top. The sand and rock colors were also generated with perlin functions, and were mixed
  between via the height of the terrain.
  - Mountains and plains are in areas of moderate moisture. They are characterized by large flat areas mixed
  with other mountainous areas. The hight map is generated with some simple fbm, but is then cubed to create the feilds.
  I added on more brownian noise to areas of higher elevation to increase the jaggedness without affecting the feilds. More interesting however is the coloration of this biome. The grass is generated with 2 noise functions, one small perlin to make the actual grass, and a larger FBM to add in occasional dirt patches. Going up, the colors (which themselves are mostly made with perlin noise) are determined by height, but to avoid horizontal bands, I perturbed the interpolation
  factor with another fbm call.
  - Areas with low moisture are oceans. The oceans themselves are flat (I wanted to make small waves, but I couldn't get
  that to look right with my islands in the short amount of time I had). The islands are generated with perlin noise that
  goes through the same steep falloff I used to make the mesas. However, here, the noise function is actually subtracted from the terrain, effectively carving out an ocean. Like the other biomes, I used height to determine if the terrain should be colored with water, sand, or grass, but I also added in the sine of time to the interpolation to create
  a tide effect (it's pretty subtle though). The ocean also uses fbm perturbed worley noise (the fbm and worley noise are
  also offset by time) to create a watery effect. A perturbed perlin is also used to change the height of the ocean, giving it a wavy effect (although, it's very subtle);
  - The different biomes are linearly interpolated between. I kept the interpolation between mountains and oceans fairly large
  so that noticable beaches could form at the edges of these biomes.

## Controls
- "Biome Size" allows users to change the size of the biome. The inverse of the input is multiplied with the frequency of the FBM that determines biome placement.
- "Time Multiplier" changes the rate at which time passes. This effects the color and height of the ocean, but also effects the sky color. I implemented an extremely primative day-night cycle (it only changes the color of the sky, which is still solid. I never implemented any sort of sun in my shader), which can be sped up or reversed using this parameter.
- I did implement some simple lambertian shading to my scene. Since the vertices are altered in the shader, I had to approximate the normals by sampling the height in two additional positions close to the vertex position, and then taking a cross product. I then use the position of the sun, which is based on time (but note the sun is not actually rendered) to compute the lambertian factor per fragment. However, on my machine, this entire process is extremely slow, so I added a boolean "Lighting" parameter to disable it entirely and increase the framerate.

## Sources
- My worley noise implementation was copied (though slightly modified) from a version I wrote in CIS460 last semester.
- I referred to the lecture slides for help when writing my FBM and perlin functions.
- I used http://www.iquilezles.org/apps/graphtoy/ to help design some of my falloff functions
- My program wouldn't run if I used an integer uniform in both by vertex and fragment shaders, so I referred to this SO post: https://stackoverflow.com/questions/22593729/accessing-same-named-uniform-in-vertex-and-fragment-shaders-fails. Once I added the highp qualifier it worked.
- I used the DAT.GUI overview (https://workshop.chromeexperiments.com/examples/gui/#1--Basic-Usage) to refresh myself on how to develop the controls.
- I used Inigo Quilez's article on domain warping (https://www.iquilezles.org/www/articles/warp/warp.htm) to help with my water animation.

## Base Code
The code we have provided for this assignment features the following:
- A subdivided plane rendered with a shader that deforms it with a sine curve
and applies a blue distance fog to it to blend it into the background. This
shader also provides a few noise functions that include "seed" input; this
value lets you offset the input vec2 by some constant value so that you can
get two different noise values for the same input position.
- A movable camera like the one provided with homework 0
- A keyboard input listener that, at present, listens for the WASD keys
and updates a `vec2` in the plane shader representing a 2D position
- A square that spans the range [-1, 1] in X and Y that is rendered with a
shader that does not apply a projection matrix to it, thus rendering it as the
"background" of your scene

When you run the program, you should see this scene:
![](startScene.png)

## Assignment Requirements
- __(75 points)__ Modify the provided terrain shader so that it incorporates various noise
functions and noise function permutations to deform the surface and
modify the color of the subdivided plane to give it the appearance of
various geographic features. Your terrain should incorporate at least three
different types of noise (different permutations count as different types).
Here are some suggestions for how to use noise to generate these features:
  - Create a height field based on summed fractal noise
  - Adjust the distribution of noise values so they are biased to various height
  values, or even radically remap height values entirely!
  ![](distributionGraphs.png)
  - Use noise functions on a broad scale to compute different terrain attributes:
    - Temperature
    - Moisture
    - Rainfall
    - Population
    - Mysticality
    - Volcanic activity
    - Urbanization
    - Storm intensity
    - Fog density (perhaps add some procedurally textured planes hovering above
      the ground)
    - Faction control in the war between the Ponies of Equestria and Manatees
    of Atlantis
  - Use the above attributes to drive visual features such as terrain height
  distribution, terrain color, water placement, noise type used to deform
  terrain, etc.
  - If you think of your terrain attributes as forming an N-dimensional space,
  you can carve out zones within that space for different kinds of environments
  and biomes, interpolating between the different kinds when you reach the
  boundary of a biome.
  - Your terrain doesn't have to be Earth-like; create any kind of outlandish
  environment you wish to!


- __(15 points)__ Add GUI elements via dat.GUI that allow the user to modify different
attributes of your terrain generator. For example, you could modify the scale
of certain noise functions to grow and shrink biome placement, or adjust the
age of your world to alter things like sea level and mountain height. You could
also modify the time of day of your scene through the GUI. Whichever elements
you choose to make controllable, you should have at least two modifiable
features.


- __(10 points)__ Following the specifications listed
[here](https://github.com/pjcozzi/Articles/blob/master/CIS565/GitHubRepo/README.md),
create your own README.md, renaming this file to INSTRUCTIONS.md. Don't worry
about discussing runtime optimization for this project. Make sure your
README contains the following information:
  - Your name and PennKey
  - Citation of any external resources you found helpful when implementing this
  assignment.
  - A link to your live github.io demo (refer to the pinned Piazza post on
    how to make a live demo through github.io)
  - An explanation of the techniques you used to generate your planet features.
  Please be as detailed as you can; not only will this help you explain your work
  to recruiters, but it helps us understand your project when we grade it!

## Inspiration
### Cliffs
![](img/cliff.jpg)

[(Image Source)](https://i.pinimg.com/236x/a6/91/7c/a6917cbe80e81736058cdcfe60e90447.jpg)

### Stairs
![](img/stairs.jpg) 

Use a sawtooth / stepping function to create stairs. [(Image Source)](https://i.pinimg.com/originals/43/ba/5c/43ba5caaeed0f24b19bbbc16f884966c.jpg)

### Pond
![](img/pond.png)

Use any obj loader to load assets into your scenes. Be sure to credit the loader in your readme! [(Image Source)](https://i.pinimg.com/originals/13/2a/2a/132a2a2bde126d0993b9ea77955cc673.jpg)



## Useful Links
- [Implicit Procedural Planet Generation](https://static1.squarespace.com/static/58a1bc3c3e00be6bfe6c228c/t/58a4d25146c3c4233fb15cc2/1487196929690/ImplicitProceduralPlanetGeneration-Report.pdf)
- [Curl Noise](https://petewerner.blogspot.com/2015/02/intro-to-curl-noise.html)
- [GPU Gems Chapter on Perlin Noise](http://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch05.html)
- [Worley Noise Implementations](https://thebookofshaders.com/12/)


## Submission
Commit and push to Github, then submit a link to your commit on Canvas. Remember
to make your own README!

## Extra Credit (20 points maximum)
- __(5 - 20 pts)__ Modify the flat shader to create a procedural background for
your scene. Add clouds, a sun (or suns!), stars, a moon, sentient nebulae,
whatever tickles your fancy! The more interesting your sky, the more points
you'll earn!
- __(5 - 10 pts)__ Use a 4D noise function to modify the terrain over time, where time is the
fourth dimension that is updated each frame. A 3D function will work, too, but
the change in noise will look more "directional" than if you use 4D.
- __(10 - 20 pts)__ Create your own mesh objects and procedurally place them
in your environment according to terrain type, e.g. trees, buildings, animals.
- __(10 - 20 pts)__ Cast a ray from your mouse and perform an action to modify the terrain (height or color), making your environment paintable.
- __(? pts)__ Propose an extra feature of your own!
