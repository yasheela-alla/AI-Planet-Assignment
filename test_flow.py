from prefect import flow, task
import time

@task
def hello_aws():
    """Simple task to test ECS deployment"""
    print("Hello from AWS ECS!")
    print("Task is running in Fargate container")
    return "ECS task completed successfully"

@flow
def test_ecs_flow():
    """Test flow to verify ECS deployment works"""
    result = hello_aws()
    print(f"Flow result: {result}")
    return result

if __name__ == "__main__":
    # Run the flow
    test_ecs_flow()
