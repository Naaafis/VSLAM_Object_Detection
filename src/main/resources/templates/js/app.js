async function fetchImageAndObjects() {
    try {
        const response = await fetch('http://127.0.0.1:5555/api/getObjects');
        if (!response.ok) {
            throw new Error('Failed to fetch image and objects');
        }
        const data = await response.json();

        displayImageAndObjects(data.objects);
    } catch (error) {
        console.error(error);
    }
}

function displayImageAndObjects(objects) {
    const objectsContainer = document.getElementById('objectsContainer');
    const container = document.getElementById('resultContainer');

    // Create a list for objects
    const objectsList = document.createElement('ul');
    objects.forEach(object => {
        const objectButton = document.createElement('button');
        objectButton.textContent = object;
        // Add event listener to each button
        objectButton.addEventListener('click', () => {
            // You can define what happens when the button is clicked
            drawPointCloud(object);
        });
        const objectItem = document.createElement('li');
        objectItem.appendChild(objectButton);
        objectsList.appendChild(objectItem);
    });

    // Append objects list to the objects container
    objectsContainer.appendChild(objectsList);

    container.style.visibility = "visible";
}


// selecting loading div
const loader = document.querySelector("#loading");

// showing loading
function displayLoading() {
    loader.classList.add("display");
}

// hiding loading 
function hideLoading() {
    loader.classList.remove("display");
}

async function startWorkflow(){
    const startButton = document.getElementById("process");
    startButton.style.display = "none";
    displayLoading();
    try {
        const response = await fetch('http://127.0.0.1:5555/runProcess');
        if (!response.ok) {
            throw new Error('Failed to fetch image and objects');
        }
        const data = await response;
        console.log(data);
        hideLoading();
    } catch (error) {
        console.error(error);
    }
    fetchImageAndObjects();
    
}
