import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["imageContainer"]
  static values = {
    projectId: String,
    isometryId: String
  }

  removeImage(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const imageContainer = button.closest('[data-image-removal-target="imageContainer"]');
    const imageId = button.dataset.imageRemovalImageIdParam;
    const imageType = button.dataset.imageRemovalImageTypeParam;
    
    // Debug logging
    console.log('Delete image data:', {
      projectId: this.projectIdValue,
      isometryId: this.isometryIdValue,
      imageId,
      imageType,
      buttonDataset: button.dataset
    });

    // Validate required data
    if (!imageId || !imageType) {
      console.error('Missing image data:', {
        imageId,
        imageType,
        buttonElement: button,
        buttonDataset: button.dataset
      });
      return;
    }

    if (!this.projectIdValue || !this.isometryIdValue) {
      console.error('Missing project/isometry data:', {
        projectId: this.projectIdValue,
        isometryId: this.isometryIdValue
      });
      return;
    }

    if (confirm('Are you sure you want to remove this image?')) {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
      const path = `/projects/${this.projectIdValue}/isometries/${this.isometryIdValue}/delete_image`;

      console.log('Making request to:', path, {
        imageId,
        imageType
      });
      
      fetch(path, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          image_id: imageId,
          image_type: imageType
        })
      })
      .then(response => {
        if (!response.ok) {
          return response.text().then(text => {
            console.error('Server response:', text);
            console.error('Status:', response.status);
            throw new Error(`Failed to remove image: ${response.status}`);
          });
        }
        return response;
      })
      .then(() => {
        imageContainer.remove();
      })
      .catch(error => {
        console.error('Error removing image:', error);
      });
    }
  }
}