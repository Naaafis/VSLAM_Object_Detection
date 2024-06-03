var renderForm = document.getElementById("render_form");
renderForm.addEventListener("change", render);

// selecting loading div
const loader = document.getElementById("loading");
hideLoading();

var objectSet = []
var traces = []
var meshes = []
var highlighted = false;

async function render(event) {

    var dataset_name = renderForm.value;

    // start loading
    displayLoading();
    console.log("Start");
    d3.json(`http://127.0.0.1:5555/api/getObjects?dataset=${dataset_name}`, function(data){
        console.log(data);
        objectSet = data;

        // build object list
        var i = 0;
        const container = document.getElementById('resultContainer')
        const objectList = document.getElementById('objectList');
        objectSet['objects'].forEach(object => {

            // create a button for that object, and store the index of the trace
            const objectButton = document.createElement('button');
            //objectButton.textContent = String(i); // text will be the index of the object
            objectButton.textContent = object["predName"]; // text will be the index of the object
            objectButton.setAttribute("idx", i);
            objectButton.title = "Object " + String(i);
            objectButton.className = "myBtn";

            // Add event listener to each button
            objectButton.addEventListener('click', () => {
                // remove all meshes from graph, and add current
                if(highlighted != false){
                    Plotly.deleteTraces('myDiv', [-1]);
                }
                else{
                    highlighted = true;
                }

                // get index of current mesh
                var i = objectButton.getAttribute("idx");
                Plotly.addTraces('myDiv', [meshes[i]]);
            });

            objectList.appendChild(objectButton);
            objectList.style.visibility = "visible";
            container.style.visibility = "visible";

            // create trace
            var currTrac = {
                x: object['points'].map((x) => x['x']),
                y: object['points'].map((x) => x['y']),
                z: object['points'].map((x) => x['z']),
                type: 'scatter3d',
                mode: 'markers',
                marker: {
                    color: object['points'].map((x) => 'rgb(' + x['R'] + ', ' + x['G'] + ', ' + x['B'] + ')'),
                    size: 3,
                    width: 0.2
                }
            }

            // create mesh
            var currMesh = {
                alphahull: 0,
                opacity: 0.9,
                type: 'mesh3d',
                x: object['points'].map((x) => x['x']),
                y: object['points'].map((x) => x['y']),
                z: object['points'].map((x) => x['z'])
            }

            // add object and mesh to lists
            traces.push(currTrac);
            meshes.push(currMesh);

            i++;
        });


        var layout = {
            margin: {
                l: 0,
                r: 0,
                b: 0,
                t: 0
            },
            showlegend: false
        };

        Plotly.newPlot('myDiv', traces, layout);

        // finish loading
        hideLoading();
    });

}



// showing loading
function displayLoading() {
    loader.style.visibility = "visible";
    console.log("HERE");
}

// hiding loading
function hideLoading() {
    loader.style.visibility = "hidden";
}
