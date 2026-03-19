package com.example.app;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String home() {
        return "Hello from Jenkins App!";
    }

    @GetMapping("/health")
    public String health() {
        return "UP";
    }
}
