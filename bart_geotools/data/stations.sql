SELECT
    metadata.name AS name,
    metadata.code AS code,
    max(metadata.latitude) AS latitude,
    max(metadata.longitude) AS longitude,
    sum(weights.count) AS count
FROM
    metadata
LEFT OUTER JOIN
    weights
ON
    weights.source = metadata.code
    OR weights.destination = metadata.code
GROUP BY
    metadata.name,
    metadata.code