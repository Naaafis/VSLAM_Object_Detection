
async function drawPointCloud(object) {
  await fetch('http://127.0.0.1:5555/getJSON')
    .then(response => response.json())
    .then(responseText => {
      let pointCloudData = parseJSONToPointCloud(responseText, object);

      // Use three.js to render the point cloud
      let scene = new THREE.Scene();
      let camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
      let renderer = new THREE.WebGLRenderer();
      renderer.setSize(window.innerWidth, window.innerHeight);
      document.body.appendChild(renderer.domElement);

      // Create a buffer geometry and add the point cloud data
      let geometry = new THREE.BufferGeometry();
      geometry.setAttribute('position', new THREE.Float32BufferAttribute(new Float32Array(pointCloudData.positions), 3));
      geometry.setAttribute('color', new THREE.Float32BufferAttribute(new Float32Array(pointCloudData.colors), 3));

      let material = new THREE.PointsMaterial({ vertexColors: true, size: 0.005 });

      let pointCloud = new THREE.Points(geometry, material);
      scene.add(pointCloud);

      camera.position.z = 2;

      let angleX = 0;
      let angleY = 0;

      // Handle user interaction for rotation
      let isDragging = false;
      let previousMousePosition = {
        x: 0,
        y: 0
      };

      // Add event listeners to renderer's DOM element
      renderer.domElement.addEventListener("mousedown", (event) => {
        isDragging = true;
        previousMousePosition = {
          x: event.clientX,
          y: event.clientY
        };
      });

      renderer.domElement.addEventListener("mousemove", (event) => {
        if (isDragging) {
          let deltaX = event.clientX - previousMousePosition.x;
          let deltaY = event.clientY - previousMousePosition.y;

          angleY += deltaX * 0.01;
          angleX += deltaY * 0.01;

          pointCloud.rotation.y = angleY;
          pointCloud.rotation.x = angleX;

          previousMousePosition = {
            x: event.clientX,
            y: event.clientY
          };

          renderer.render(scene, camera);
        }
      });

      renderer.domElement.addEventListener("mouseup", () => {
        isDragging = false;
      });

      let zoomFactor = 1; // Initial zoom level

      const zoomSensitivity = 0.01; // Adjust zoom sensitivity as needed

      renderer.domElement.addEventListener("wheel", (event) => {
        event.preventDefault();

        zoomFactor += event.deltaY * zoomSensitivity;
        zoomFactor = Math.max(0.1, zoomFactor); // Enforce minimum zoom level
        camera.position.z = camera.initialPosition.z / zoomFactor;
        renderer.render(scene, camera);
      });

      camera.initialPosition = { z: camera.position.z }; // Store initial position

      function animate() {
        requestAnimationFrame(animate);
        renderer.render(scene, camera);
      }

      animate();

      function parseJSONToPointCloud(jsonObject, target) {
        // Initialize point cloud data
        let positions = [];
        let colors = [];
      
        // Check if the object name exists in the JSON
        if (target in jsonObject || target == null) {
          
          for (let objectKey in jsonObject) {
            let object = jsonObject[objectKey]['pset'];

            // Loop through each coordinate in the object
            for (let i = 0; i < object.length; i++) {
              let coordinate = object[i];
              
              // Extract x, y, z values
              let x = coordinate['x'];
              let y = coordinate['y'];
              let z = coordinate['z'];
              let r,g,b;
              
              if(objectKey == target){
                console.log(target);
                r = 1; // Red component
                g = 0; // Green component
                b = 0; // Blue component
              } else {
                r = 1;
                g = 1;
                b = 1;
              }

              // Push to positions list
              positions.push(x, y, z );
              colors.push(r,g,b);
            }
          }

        } else {
          console.error(`Object '${object}' not found in JSON.`);
        }
      
        return { positions: positions, colors: colors };
      }
    })
    .catch(error => {
      console.error('Error loading JSON:', error);
    });
}