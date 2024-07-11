async function export_all() {
    const vulns = document.getElementsByClassName('v-list-item--link');
    const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
    const logArea = document.createElement('div');
    document.body.appendChild(logArea);

    const log = message => {
        console.log(message);
        const logEntry = document.createElement('p');
        logEntry.textContent = message;
        logArea.appendChild(logEntry);
    };

    for (const vuln of vulns) {
        try {
            const uuid = vuln.href.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/)[0];
            const export_link = `/api/v1/findingtemplates/${uuid}/export/`;
            const response = await fetch(export_link, {
                method: "POST",
                body: "{}",
                headers: {
                    "Content-Type": "application/json"
                }
            });

            if (!response.ok) {
                throw new Error(`Failed to export ${uuid}: ${response.statusText}`);
            }

            const blob = await response.blob();
            const fileURL = URL.createObjectURL(blob);
            const fileLink = document.createElement('a');
            fileLink.href = fileURL;
            fileLink.download = `${uuid}.tar.gz`;
            fileLink.click();

            log(`Successfully exported: ${uuid}`);
        } catch (error) {
            log(`Error: ${error.message}`);
        }

        // Pause between requests to avoid overloading the server
        await delay(500); // Adjust delay as necessary
    }

    log("Export process completed.");
}

export_all();
